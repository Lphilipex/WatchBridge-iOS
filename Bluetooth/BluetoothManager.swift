
import Foundation
import CoreBluetooth
import Combine

struct BluetoothCharacteristicInfo: Identifiable {
    let characteristic: CBCharacteristic
    var value: String = "Ainda não consultada"

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

    @Published var devices: [WatchDevice] = []
    @Published var discoveredServices: [String] = []
    @Published var discoveredCharacteristics: [BluetoothCharacteristicInfo] = []

    @Published var connectedDeviceName: String?
    @Published var status = "Aguardando Bluetooth"

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

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

        case .poweredOff:
            isBluetoothReady = false
            status = "Bluetooth desligado"

        case .unauthorized:
            isBluetoothReady = false
            status = "Permissão Bluetooth negada"

        case .unsupported:
            isBluetoothReady = false
            status = "Bluetooth não suportado"

        default:
            isBluetoothReady = false
            status = "Verificando Bluetooth..."
        }
    }

    // MARK: - Busca de dispositivos

    func startScan() {
        guard central.state == .poweredOn else {
            status = "Ative o Bluetooth"
            return
        }

        devices.removeAll()

        isScanning = true
        status = "Procurando dispositivos..."

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
        }
    }

    // MARK: - Conexão BLE

    func connect(to device: WatchDevice) {
        guard central.state == .poweredOn else {
            status = "Bluetooth indisponível"
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

        central.connect(
            device.peripheral,
            options: nil
        )
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else {
            return
        }

        status = "Desconectando..."

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
            print("Erro de conexão BLE: \(error.localizedDescription)")
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
    }

    // MARK: - Descoberta de serviços GATT

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        if let error = error {
            status = "Erro ao procurar serviços"
            print("Erro GATT: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else {
            status = "Nenhum serviço encontrado"
            return
        }

        discoveredServices = services.map {
            $0.uuid.uuidString
        }

        status = "\(services.count) serviço(s) encontrado(s)"

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
            print("Erro nas características: \(error.localizedDescription)")
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

        peripheral.readValue(
            for: info.characteristic
        )
    }

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
    }
}
