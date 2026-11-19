
import SwiftUI

struct DashboardView: View {
    @StateObject private var bluetooth = BluetoothManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Image(systemName: "applewatch")
                    .font(.system(size: 65))
                    .foregroundStyle(.blue)

                Text("WatchBridge")
                    .font(.largeTitle.bold())

                Text("Galaxy Watch 4 Classic")
                    .font(.headline)

                Text(bluetooth.status)
                    .foregroundStyle(.secondary)

                if bluetooth.isScanning {
                    Button("Parar busca") {
                        bluetooth.stopScan()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Procurar relógio") {
                        bluetooth.startScan()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!bluetooth.isBluetoothReady)
                }

                Divider()

                HStack {
                    Text("Dispositivos encontrados")
                        .font(.headline)

                    Spacer()

                    Text("\(bluetooth.devices.count)")
                        .foregroundStyle(.secondary)
                }

                List(bluetooth.devices) { device in
                    VStack(alignment: .leading, spacing: 6) {

                        HStack {
                            Text(device.name)
                                .font(.headline)

                            Spacer()

                            if device.isLikelyGalaxyWatch {
                                Text("Possível Galaxy Watch")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }

                        Text(device.id.uuidString)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Sinal Bluetooth: \(device.rssi) dBm")
                            .font(.caption)

                        if device.isLikelyGalaxyWatch {
                            Label(
                                "Possível dispositivo Samsung",
                                systemImage: "applewatch"
                            )
                            .font(.caption)
                            .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .navigationTitle("WatchBridge")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
