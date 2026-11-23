
import Foundation
import CoreBluetooth

struct WatchDevice: Identifiable {

    // MARK: - Dispositivo Bluetooth

    let peripheral: CBPeripheral

    // MARK: - Informações recebidas

    let rssi: Int
    let advertisedName: String?
    let advertisedServices: [String]
    let manufacturerData: String?

    // MARK: - Identificação

    var id: UUID {
        peripheral.identifier
    }

    var name: String {
        advertisedName
            ?? peripheral.name
            ?? "Dispositivo desconhecido"
    }

    // MARK: - Identificação provável do Galaxy Watch

    var isLikelyGalaxyWatch: Bool {
        let deviceName = name.lowercased()

        return deviceName.contains("galaxy watch")
            || deviceName.contains("samsung")
            || deviceName.contains("sm-r")
    }
}
