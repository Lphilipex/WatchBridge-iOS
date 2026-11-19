
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

    var isLikelyGalaxyWatch: Bool {
        let deviceName = name.lowercased()

        return deviceName.contains("galaxy watch")
            || deviceName.contains("samsung")
            || deviceName.contains("sm-r")
    }
}
