import Foundation
import CoreBluetooth

struct WatchDevice: Identifiable {

    let peripheral: CBPeripheral
    let rssi: Int

    var id: UUID {
        peripheral.identifier
    }

    var name: String {
        peripheral.name ?? "Dispositivo desconhecido"
    }
}
