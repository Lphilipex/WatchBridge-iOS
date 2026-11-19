
import Foundation
import CoreBluetooth
import Combine

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
    @Published var discoveredCharacteristics: [String] = []

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

        // Solicita a lista de serviços GATT.
        peripheral.discoverServices(nil)
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        isConnecting = false
        isConnected = false

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

        // Solicita as características de cada serviço.
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
            let information = """
            Serviço: \(service.uuid.uuidString)
            Característica: \(characteristic.uuid.uuidString)
            Propriedades: \(characteristic.properties)
            """

            discoveredCharacteristics.append(information)
        }

        status = "Características Bluetooth identificadas"
    }
}
