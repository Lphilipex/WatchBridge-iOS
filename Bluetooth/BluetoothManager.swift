
import Foundation
import CoreBluetooth
import Combine

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

final class BluetoothManager: NSObject,
    ObservableObject,
    CBCentralManagerDelegate,
    CBPeripheralDelegate {

    @Published var isBluetoothReady = false
    @Published var isScanning = false
    @Published var isConnecting = false
    @Published var isConnected = false

    @Published var notificationEvents: [String] = []
    @Published var diagnosticEvents: [String] = []

    @Published var devices: [WatchDevice] = []
    @Published var discoveredServices: [String] = []
    @Published var discoveredCharacteristics: [BluetoothCharacteristicInfo] = []

    @Published var connectedDeviceName: String?
    @Published var status = "Aguardando Bluetooth"

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    // MARK: - Relatório de diagnóstico

    private var diagnosticDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter
    }()

    var diagnosticReport: String {
        var report = """
        WATCHBRIDGE - RELATÓRIO DE DIAGNÓSTICO
        ======================================

        Data da exportação: \(diagnosticDateFormatter.string(from: Date()))
        Estado do Bluetooth: \(isBluetoothReady ? "Disponível" : "Indisponível")
        Estado da conexão: \(isConnected ? "Conectado" : "Desconectado")
        Dispositivo: \(connectedDeviceName ?? "Nenhum")
        Status atual: \(status)

        RESUMO
        ------
        Dispositivos encontrados: \(devices.count)
        Serviços identificados: \(discoveredServices.count)
        Características identificadas: \(discoveredCharacteristics.count)
        Eventos de notificações: \(notificationEvents.count)
        Eventos de diagnóstico: \(diagnosticEvents.count)

        SERVIÇOS GATT
        -------------
        """

        if discoveredServices.isEmpty {
            report += "\nNenhum serviço identificado."
        } else {
            for service in discoveredServices {
                report += "\n- \(service)"
            }
        }

        report += "\n\nCARACTERÍSTICAS BLUETOOTH\n-------------------------"

        if discoveredCharacteristics.isEmpty {
            report += "\nNenhuma característica identificada."
        } else {
            for characteristic in discoveredCharacteristics {
                report += """

                
                Serviço: \(characteristic.serviceUUID)
                UUID: \(characteristic.uuid)
                Propriedades: \(characteristic.propertiesDescription)
                Leitura permitida: \(characteristic.isReadable ? "Sim" : "Não")
                Notificações: \(characteristic.notificationsEnabled ? "Ativadas" : "Desativadas")
                Valor: \(characteristic.value)
                """
            }
        }

        report += "\n\nHISTÓRICO DE NOTIFICAÇÕES\n-------------------------"

        if notificationEvents.isEmpty {
            report += "\nNenhuma notificação recebida."
        } else {
            report += "\n" + notificationEvents.joined(separator: "\n")
        }

        report += "\n\nHISTÓRICO DE DIAGNÓSTICO\n------------------------"

        if diagnosticEvents.isEmpty {
            report += "\nNenhum evento registrado."
        } else {
            report += "\n" + diagnosticEvents.joined(separator: "\n")
        }

        report += "\n\nFim do relatório."

        return report
    }

    override init() {
        super.init()

        central = CBCentralManager(
            delegate: self,
            queue: .main
        )
    }

    // MARK: - Registro de eventos

    private func log(_ message: String) {
        let date = diagnosticDateFormatter.string(from: Date())
        let event = "[\(date)] \(message)"

        diagnosticEvents.insert(event, at: 0)

        if diagnosticEvents.count > 100 {
            diagnosticEvents.removeLast()
        }

        print(event)
    }

    private func logNotification(_ message: String) {
        notificationEvents.insert(message, at: 0)

        if notificationEvents.count > 50 {
            notificationEvents.removeLast()
        }

        log("Notificação: \(message)")
    }

    // MARK: - Estado do Bluetooth

    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {
        switch central.state {
        case .poweredOn:
            isBluetoothReady = true
            status = "Bluetooth disponível"
            log("Bluetooth ligado e disponível.")

        case .poweredOff:
            isBluetoothReady = false
            status = "Bluetooth desligado"
            log("Bluetooth desligado.")

        case .unauthorized:
            isBluetoothReady = false
            status = "Permissão Bluetooth negada"
            log("Permissão de Bluetooth não autorizada.")

        case .unsupported:
            isBluetoothReady = false
            status = "Bluetooth não suportado"
            log("Bluetooth não suportado neste dispositivo.")

        default:
            isBluetoothReady = false
            status = "Verificando Bluetooth..."
            log("Estado do Bluetooth: \(central.state.rawValue).")
        }
    }

    // MARK: - Busca de dispositivos

    func startScan() {
        guard central.state == .poweredOn else {
            status = "Ative o Bluetooth"
            log("Busca não iniciada: Bluetooth indisponível.")
            return
        }

        devices.removeAll()

        isScanning = true
        status = "Procurando dispositivos..."

        log("Busca BLE iniciada.")

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

        log("Busca BLE finalizada. Dispositivos encontrados: \(devices.count).")
    }

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
            log("Dispositivo encontrado: \(device.name), sinal: \(RSSI) dBm.")
        }
    }

    // MARK: - Conexão BLE

    func connect(to device: WatchDevice) {
        guard central.state == .poweredOn else {
            status = "Bluetooth indisponível"
            log("Conexão não iniciada: Bluetooth indisponível.")
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

        log("Solicitada conexão com \(device.name).")

        central.connect(
            device.peripheral,
            options: nil
        )
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else {
            log("Solicitação de desconexão ignorada: nenhum dispositivo conectado.")
            return
        }

        status = "Desconectando..."
        log("Solicitada desconexão de \(peripheral.name ?? "dispositivo").")

        central.cancelPeripheralConnection(peripheral)
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        isConnecting = false
        isConnected = true

        connectedDeviceName = peripheral.name ?? "Dispositivo conectado"
        status = "Conectado a \(connectedDeviceName ?? "dispositivo")"

        log("Conexão estabelecida com \(connectedDeviceName ?? "dispositivo").")
        log("Iniciando descoberta dos serviços GATT.")

        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

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

        if let error = error {
            log("Falha na conexão: \(error.localizedDescription)")
        } else {
            log("Falha na conexão: motivo não informado.")
        }
    }

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

        if let error = error {
            log("Dispositivo desconectado com erro: \(error.localizedDescription)")
        } else {
            log("Dispositivo desconectado normalmente.")
        }
    }

    // MARK: - Descoberta de serviços GATT

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        if let error = error {
            status = "Erro ao procurar serviços"
            log("Erro na descoberta de serviços: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else {
            status = "Nenhum serviço encontrado"
            log("Nenhum serviço GATT encontrado.")
            return
        }

        discoveredServices = services.map {
            $0.uuid.uuidString
        }

        status = "\(services.count) serviço(s) encontrado(s)"

        log("Descoberta concluída: \(services.count) serviço(s) GATT.")

        for service in services {
            log("Solicitando características do serviço \(service.uuid.uuidString).")

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
            log("Erro ao descobrir características de \(service.uuid): \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else {
            log("Nenhuma característica encontrada no serviço \(service.uuid).")
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

                log(
                    "Característica encontrada: \(info.uuid). Propriedades: \(info.propertiesDescription)."
                )
            }
        }

        status = "Características Bluetooth identificadas"

        log(
            "Serviço \(service.uuid.uuidString): \(characteristics.count) característica(s) encontrada(s)."
        )
    }

    // MARK: - Leitura de características

    func readCharacteristic(
        _ info: BluetoothCharacteristicInfo
    ) {
        guard isConnected,
              let peripheral = connectedPeripheral else {
            status = "Nenhum dispositivo conectado"
            log("Leitura não realizada: nenhum dispositivo conectado.")
            return
        }

        guard info.isReadable else {
            status = "Esta característica não permite leitura"
            log("Leitura não permitida para a característica \(info.uuid).")
            return
        }

        status = "Solicitando leitura..."
        log("Solicitada leitura da característica \(info.uuid).")

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
            log("Notificação não configurada: nenhum dispositivo conectado.")
            return
        }

        guard info.supportsNotifications else {
            status = "Característica não suporta notificações"
            log("Característica \(info.uuid) não suporta notificações.")
            return
        }

        let enable = !info.notificationsEnabled

        status = enable
            ? "Ativando notificações..."
            : "Desativando notificações..."

        log(
            "\(enable ? "Solicitada ativação" : "Solicitada desativação") das notificações da característica \(info.uuid)."
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
            log("Atualização de notificação recebida para característica não registrada: \(characteristic.uuid).")
            return
        }

        if let error = error {
            status = "Erro ao configurar notificação"

            log("Erro ao configurar notificação: \(error.localizedDescription)")

            logNotification(
                "Erro: \(error.localizedDescription)"
            )

            return
        }

        discoveredCharacteristics[index].notificationsEnabled =
            characteristic.isNotifying

        if characteristic.isNotifying {
            status = "Notificações ativadas"

            logNotification(
                "Notificações ativadas: \(characteristic.uuid.uuidString)"
            )
        } else {
            status = "Notificações desativadas"

            logNotification(
                "Notificações desativadas: \(characteristic.uuid.uuidString)"
            )
        }
    }

    // MARK: - Recebimento de dados BLE

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
            log("Dados recebidos de uma característica não registrada: \(characteristic.uuid).")
            return
        }

        if let error = error {
            discoveredCharacteristics[index].value =
                "Erro: \(error.localizedDescription)"

            status = "Erro durante a leitura"

            log("Erro ao receber dados da característica \(characteristic.uuid): \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            discoveredCharacteristics[index].value =
                "Nenhum dado recebido"

            status = "Leitura sem dados"

            log("Nenhum dado recebido da característica \(characteristic.uuid).")
            return
        }

        let hexadecimal = data.map {
            String(format: "%02X", $0)
        }.joined(separator: " ")

        discoveredCharacteristics[index].value = hexadecimal
        status = "Leitura concluída"

        log(
            "Dados recebidos da característica \(characteristic.uuid.uuidString): \(hexadecimal)"
        )

        if characteristic.isNotifying {
            logNotification(
                "Atualização recebida: \(characteristic.uuid.uuidString) = \(hexadecimal)"
            )
        }
    }
}
