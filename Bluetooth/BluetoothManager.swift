import Foundation
import CoreBluetooth
import Combine

final class BluetoothManager: NSObject,
    ObservableObject,
    CBCentralManagerDelegate {

    @Published var isBluetoothReady = false
    @Published var isScanning = false
    @Published var devices: [WatchDevice] = []
    @Published var status = "Aguardando Bluetooth"

    private var central: CBCentralManager!

    override init() {
        super.init()

        central = CBCentralManager(
            delegate: self,
            queue: .main
        )
    }

    // Verifica o estado do Bluetooth
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

    // Inicia a busca por dispositivos
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

    // Interrompe a busca
    func stopScan() {

        central.stopScan()

        isScanning = false
        status = "Busca finalizada"
    }

    // Recebe os dispositivos encontrados
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
}