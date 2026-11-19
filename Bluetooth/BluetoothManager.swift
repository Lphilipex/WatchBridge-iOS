
import Foundation
import CoreBluetooth
import Combine

// MARK: - Informações das características Bluetooth

struct BluetoothCharacteristicInfo: Identifiable {

    let characteristic: CBCharacteristic

    var value: String = "Ainda não consultada"
    var notificationsEnabled = false

    var id: String {
        "\(serviceUUID)-\(uuid)"
    }

    var serviceUUID: String {
        characteristic.service?.uuid.uuidString ?? "Desconhecido"
    }

    var uuid: String {
        characteristic.uuid.uuidString
    }

    var isReadable: Bool {
        characteristic.properties.contains(.read)
    }

    var supportsNotifications: Bool {
        characteristic.properties.contains(.notify)
            || characteristic.properties.contains(.indicate)
    }

    var propertiesDescription: String {
        var properties: [String] = []

        if characteristic.properties.contains(.read) {
            properties.append("Leitura")
        }

        if characteristic.properties.contains(.write) {
            properties.append("Escrita")
        }

        if characteristic.properties.contains(.writeWithoutResponse) {
            properties.append("Escrita sem resposta")
        }

        if characteristic.properties.contains(.notify) {
            properties.append("Notificações")
        }

        if characteristic.properties.contains(.indicate) {
            properties.append("Indicações")
        }

        return properties.isEmpty
            ? "Propriedades não identificadas"
            : properties.joined(separator: ", ")
    }
}

// MARK: - Gerenciador Bluetooth

final class BluetoothManager: NSObject,
    ObservableObject,
    CBCentralManagerDelegate,
    CBPeripheralDelegate {

    // MARK: - Estados

    @Published var isBluetoothReady = false
    @Published var isScanning = false
    @Published var isConnecting = false
    @Published var isConnected = false

    // MARK: - Dados Bluetooth

    @Published var notificationEvents: [String] = []
    @Published var diagnosticEvents: [String] = []

    @Published var devices: [WatchDevice] = []
    @Published var discoveredServices: [String] = []

    @Published var discoveredCharacteristics:
        [BluetoothCharacteristicInfo] = []

    @Published var connectedDeviceName: String?

    @Published var status = "Aguardando Bluetooth"

    // MARK: - Objetos Bluetooth

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    // MARK: - Relatório de diagnóstico

    var diagnosticReport: String {

        """
        WATCHBRIDGE - RELATÓRIO DE DIAGNÓSTICO

        Data: \(Date())

        Status: \(status)

        Bluetooth: \(isBluetoothReady ? "Disponível" : "Indisponível")

        Conexão: \(isConnected ? "Conectado" : "Desconectado")

        Dispositivo: \(connectedDeviceName ?? "Nenhum")

        Dispositivos encontrados: \(devices.count)

        Serviços GATT: \(discoveredServices.count)

        Características: \(discoveredCharacteristics.count)

        Notificações: \(notificationEvents.count)


        SERVIÇOS GATT:

        \(discoveredServices.joined(separator: "\n"))


        EVENTOS DE DIAGNÓSTICO:

        \(diagnosticEvents.joined(separator: "\n"))


        EVENTOS BLE:

        \(notificationEvents.joined(separator: "\n"))
        """
    }

    // MARK: - Registro de eventos

    private func registerDiagnosticEvent(_ message: String) {

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"

        let timestamp = formatter.string(from: Date())

        let event = "[\(timestamp)] \(message)"

        diagnosticEvents.insert(event, at: 0)

        if diagnosticEvents.count > 50 {
            diagnosticEvents.removeLast()
        }
    }

    private func registerNotificationEvent(_ message: String) {

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        let timestamp = formatter.string(from: Date())

        let event = "[\(timestamp)] \(message)"

        notificationEvents.insert(event, at: 0)

        if notificationEvents.count > 50 {
            notificationEvents.removeLast()
        }
    }

    // MARK: - Inicialização

    override init() {

        super.init()

        central = CBCentralManager(
            delegate: self,
            queue: .main
        )
    }

    // MARK: - Estado do Bluetooth

    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {

        switch central.state {

        case .poweredOn:

            isBluetoothReady = true
            status = "Bluetooth disponível"

            registerDiagnosticEvent(
                "Bluetooth ligado e disponível"
            )

        case .poweredOff:

            isBluetoothReady = false
            status = "Bluetooth desligado"

            registerDiagnosticEvent(
                "Bluetooth desligado"
            )

        case .unauthorized:

            isBluetoothReady = false
            status = "Permissão Bluetooth negada"

            registerDiagnosticEvent(
                "Permissão Bluetooth negada"
            )

        case .unsupported:

            isBluetoothReady = false
            status = "Bluetooth não suportado"

            registerDiagnosticEvent(
                "Bluetooth não suportado"
            )

        default:

            isBluetoothReady = false
            status = "Verificando Bluetooth..."

            registerDiagnosticEvent(
                "Estado Bluetooth: \(central.state.rawValue)"
            )
        }
    }

    // MARK: - Busca de dispositivos

    func startScan() {

        guard central.state == .poweredOn else {

            status = "Ative o Bluetooth"

            registerDiagnosticEvent(
                "Busca não iniciada: Bluetooth indisponível"
            )

            return
        }

        devices.removeAll()

        isScanning = true
        status = "Procurando dispositivos..."

        registerDiagnosticEvent(
            "Busca BLE iniciada"
        )

        central.scanForPeripherals(
            withServices: nil,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ]
        )
    }

    func stopScan() {

        central.stopScan()

        isScanning = false
        status = "Busca finalizada"

        registerDiagnosticEvent(
            "Busca BLE finalizada"
        )
    }

    // MARK: - Dispositivos encontrados

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {

        let device = WatchDevice(
            peripheral: peripheral,
            rssi: RSSI.intValue
        )

        if let index = devices.firstIndex(
            where: { $0.id == device.id }
        ) {

            devices[index] = device

        } else {

            devices.append(device)

            registerDiagnosticEvent(
                "Dispositivo encontrado: \(device.name) | RSSI: \(device.rssi) dBm"
            )
        }
    }

    // MARK: - Conexão BLE

    func connect(to device: WatchDevice) {

        guard central.state == .poweredOn else {

            status = "Bluetooth indisponível"

            registerDiagnosticEvent(
                "Conexão não iniciada: Bluetooth indisponível"
            )

            return
        }

        if isScanning {
            stopScan()
        }

        discoveredServices.removeAll()
        discoveredCharacteristics.removeAll()

        connectedPeripheral = device.peripheral
        connectedPeripheral?.delegate = self

        isConnecting = true
        isConnected = false

        connectedDeviceName = device.name

        status = "Conectando a \(device.name)..."

        registerDiagnosticEvent(
            "Tentativa de conexão: \(device.name)"
        )

        central.connect(
            device.peripheral,
            options: nil
        )
    }

    // MARK: - Desconectar

    func disconnect() {

        guard let peripheral = connectedPeripheral else {
            return
        }

        status = "Desconectando..."

        registerDiagnosticEvent(
            "Solicitação de desconexão"
        )

        central.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Conexão estabelecida

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {

        isConnecting = false
        isConnected = true

        connectedDeviceName =
            peripheral.name ?? "Dispositivo conectado"

        status = "Conectado a \(connectedDeviceName ?? "dispositivo")"

        registerDiagnosticEvent(
            "Conexão estabelecida com \(connectedDeviceName ?? "dispositivo")"
        )

        peripheral.delegate = self

        peripheral.discoverServices(nil)
    }

    // MARK: - Falha na conexão

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {

        isConnecting = false
        isConnected = false

        connectedDeviceName = nil
        connectedPeripheral = nil

        status = "Não foi possível conectar"

        registerDiagnosticEvent(
            "Falha na conexão: \(error?.localizedDescription ?? "Motivo não informado")"
        )
    }

    // MARK: - Desconexão

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {

        isConnecting = false
        isConnected = false

        connectedDeviceName = nil
        connectedPeripheral = nil

        discoveredServices.removeAll()
        discoveredCharacteristics.removeAll()

        status = "Dispositivo desconectado"

        registerDiagnosticEvent(
            "Dispositivo desconectado: \(peripheral.name ?? "Desconhecido")"
        )

        if let error = error {

            registerDiagnosticEvent(
                "Detalhe da desconexão: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Descoberta de serviços GATT

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {

        if let error = error {

            status = "Erro ao procurar serviços"

            registerDiagnosticEvent(
                "Erro na descoberta GATT: \(error.localizedDescription)"
            )

            return
        }

        guard let services = peripheral.services else {

            status = "Nenhum serviço encontrado"

            registerDiagnosticEvent(
                "Nenhum serviço GATT encontrado"
            )

            return
        }

        discoveredServices = services.map {
            $0.uuid.uuidString
        }

        status = "\(services.count) serviço(s) encontrado(s)"

        registerDiagnosticEvent(
            "Descoberta GATT concluída: \(services.count) serviço(s)"
        )

        for service in services {

            peripheral.discoverCharacteristics(
                nil,
                for: service
            )
        }
    }

    // MARK: - Descoberta de características

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {

        if let error = error {

            registerDiagnosticEvent(
                "Erro nas características: \(error.localizedDescription)"
            )

            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        for characteristic in characteristics {

            let info = BluetoothCharacteristicInfo(
                characteristic: characteristic
            )

            if !discoveredCharacteristics.contains(
                where: { $0.id == info.id }
            ) {

                discoveredCharacteristics.append(info)
            }
        }

        status = "Características Bluetooth identificadas"

        registerDiagnosticEvent(
            "\(characteristics.count) característica(s) encontradas no serviço \(service.uuid.uuidString)"
        )
    }

    // MARK: - Leitura de características

    func readCharacteristic(
        _ info: BluetoothCharacteristicInfo
    ) {

        guard isConnected,
              let peripheral = connectedPeripheral else {

            status = "Nenhum dispositivo conectado"
            return
        }

        guard info.isReadable else {

            status = "Esta característica não permite leitura"
            return
        }

        status = "Solicitando leitura..."

        registerDiagnosticEvent(
            "Solicitada leitura da característica \(info.uuid)"
        )

        peripheral.readValue(
            for: info.characteristic
        )
    }

    // MARK: - Notificações BLE

    func toggleNotifications(
        _ info: BluetoothCharacteristicInfo
    ) {

        guard isConnected,
              let peripheral = connectedPeripheral else {

            status = "Nenhum dispositivo conectado"
            return
        }

        guard info.supportsNotifications else {

            status = "Característica não suporta notificações"
            return
        }

        let enable = !info.notificationsEnabled

        status = enable
            ? "Ativando notificações..."
            : "Desativando notificações..."

        registerDiagnosticEvent(
            "\(enable ? "Solicitada ativação" : "Solicitada desativação") de notificações: \(info.uuid)"
        )

        peripheral.setNotifyValue(
            enable,
            for: info.characteristic
        )
    }

    // MARK: - Estado das notificações

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {

        let characteristicID = """
        \(characteristic.service?.uuid.uuidString ?? "Desconhecido")-\(characteristic.uuid.uuidString)
        """

        guard let index = discoveredCharacteristics.firstIndex(
            where: { $0.id == characteristicID }
        ) else {
            return
        }

        if let error = error {

            status = "Erro ao configurar notificação"

            let message = "Erro: \(error.localizedDescription)"

            registerNotificationEvent(message)
            registerDiagnosticEvent(message)

            return
        }

        discoveredCharacteristics[index].notificationsEnabled =
            characteristic.isNotifying

        if characteristic.isNotifying {

            status = "Notificações ativadas"

        } else {

            status = "Notificações desativadas"
        }

        let message = characteristic.isNotifying
            ? "Notificações ativadas: \(characteristic.uuid.uuidString)"
            : "Notificações desativadas: \(characteristic.uuid.uuidString)"

        registerNotificationEvent(message)
        registerDiagnosticEvent(message)
    }

    // MARK: - Atualização de valores

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {

        let characteristicID = """
        \(characteristic.service?.uuid.uuidString ?? "Desconhecido")-\(characteristic.uuid.uuidString)
        """

        guard let index = discoveredCharacteristics.firstIndex(
            where: { $0.id == characteristicID }
        ) else {
            return
        }

        if let error = error {

            discoveredCharacteristics[index].value =
                "Erro: \(error.localizedDescription)"

            status = "Erro durante a leitura"

            registerDiagnosticEvent(
                "Erro na leitura \(characteristic.uuid.uuidString): \(error.localizedDescription)"
            )

            return
        }

        guard let data = characteristic.value else {

            discoveredCharacteristics[index].value =
                "Nenhum dado recebido"

            status = "Leitura sem dados"

            return
        }

        let hexadecimal = data.map {
            String(format: "%02X", $0)
        }.joined(separator: " ")

        discoveredCharacteristics[index].value = hexadecimal

        status = "Leitura concluída"

        registerDiagnosticEvent(
            "Valor recebido da característica \(characteristic.uuid.uuidString): \(hexadecimal)"
        )

        if characteristic.isNotifying {

            registerNotificationEvent(
                "Atualização recebida: \(characteristic.uuid.uuidString) = \(hexadecimal)"
            )
        }
    }
}
