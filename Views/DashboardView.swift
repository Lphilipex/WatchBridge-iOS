
import SwiftUI

struct DashboardView: View {
    @StateObject private var bluetooth = BluetoothManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {

                Image(systemName: "applewatch")
                    .font(.system(size: 55))
                    .foregroundStyle(.blue)

                Text("WatchBridge")
                    .font(.largeTitle.bold())

                Text("Galaxy Watch 4 Classic")
                    .font(.headline)

                Text(bluetooth.status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if bluetooth.isConnected {
                    Label(
                        "Conectado: \(bluetooth.connectedDeviceName ?? "Dispositivo")",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)

                    Button("Desconectar") {
                        bluetooth.disconnect()
                    }
                    .buttonStyle(.bordered)

                } else if bluetooth.isConnecting {
                    ProgressView("Conectando...")

                } else if bluetooth.isScanning {
                    Button("Parar busca") {
                        bluetooth.stopScan()
                    }
                    .buttonStyle(.bordered)

                } else {
                    Button("Procurar dispositivos") {
                        bluetooth.startScan()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!bluetooth.isBluetoothReady)
                }

                Divider()

                List {
                    Section("Dispositivos encontrados") {
                        if bluetooth.devices.isEmpty {
                            Text("Nenhum dispositivo encontrado")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(bluetooth.devices) { device in
                            Button {
                                bluetooth.connect(to: device)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(device.name)
                                            .font(.headline)

                                        Spacer()

                                        if device.isLikelyGalaxyWatch {
                                            Text("Samsung?")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                        }
                                    }

                                    Text(device.id.uuidString)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text("Sinal: \(device.rssi) dBm")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("Toque para conectar")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .disabled(
                                bluetooth.isConnected ||
                                bluetooth.isConnecting
                            )
                        }
                    }

                    if bluetooth.isConnected {
                        Section("Serviços GATT") {
                            if bluetooth.discoveredServices.isEmpty {
                                Text("Aguardando serviços...")
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(
                                bluetooth.discoveredServices,
                                id: \.self
                            ) { service in
                                Text(service)
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                        }

                        Section("Características Bluetooth") {
                            if bluetooth.discoveredCharacteristics.isEmpty {
                                Text("Aguardando características...")
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(
                                bluetooth.discoveredCharacteristics
                            ) { characteristic in

                                VStack(alignment: .leading, spacing: 7) {
                                    Text("UUID: \(characteristic.uuid)")
                                        .font(.caption)
                                        .textSelection(.enabled)

                                    Text("Serviço: \(characteristic.serviceUUID)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)

                                    Text("Propriedades: \(characteristic.propertiesDescription)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text("Valor: \(characteristic.value)")
                                        .font(.caption)
                                        .textSelection(.enabled)

                                    if characteristic.isReadable {
                                        Button("Ler característica") {
                                            bluetooth.readCharacteristic(
                                                characteristic
                                            )
                                        }
                                        .buttonStyle(.bordered)
                                    } else {
                                        Text("Leitura não disponível")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("WatchBridge")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
