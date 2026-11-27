
import Foundation
import CoreBluetooth

/// O iPhone atua como periférico BLE e anuncia o serviço Ponte
/// para que o aplicativo do relógio possa se conectar como central.
final class BLEPeripheralService: NSObject, CBPeripheralManagerDelegate {

    // MARK: - Comunicação com o aplicativo

    var onStatus: ((String) -> Void)?
    var onMessage: ((ReassembledMessage) -> Void)?

    /// Exige pareamento/criptografia para escrita quando habilitado.
    var requireEncryption = false

    // MARK: - Bluetooth

    private var manager: CBPeripheralManager!
    private var controlChar: CBMutableCharacteristic?

    private let reassembler = ChunkReassembler()

    // MARK: - Fila de confirmações

    private var pendingAcks: [Data] = []

    private var hasControlSubscriber = false

    // MARK: - Inicialização

    override init() {
        super.init()

        manager = CBPeripheralManager(
            delegate: self,
            queue: .main
        )
    }

    // MARK: - Estado do Bluetooth

    func peripheralManagerDidUpdateState(
        _ peripheral: CBPeripheralManager
    ) {

        switch peripheral.state {

        case .poweredOn:
            setupService()

        case .poweredOff:
            hasControlSubscriber = false
            pendingAcks.removeAll()
            controlChar = nil
            reassembler.reset()
            onStatus?("Bluetooth desligado")

        case .unauthorized:
            hasControlSubscriber = false
            onStatus?("Sem permissão de Bluetooth")

        default:
            hasControlSubscriber = false
            onStatus?("Bluetooth indisponível")
        }
    }

    // MARK: - Configuração do serviço

    private func setupService() {

        let data = CBMutableCharacteristic(
            type: BridgeProtocol.dataUUID,
            properties: [.write],
            value: nil,
            permissions: requireEncryption
                ? [.writeEncryptionRequired]
                : [.writeable]
        )

        let control = CBMutableCharacteristic(
            type: BridgeProtocol.controlUUID,
            properties: [.notify],
            value: nil,
            permissions: [.readable]
        )

        controlChar = control

        let service = CBMutableService(
            type: BridgeProtocol.serviceUUID,
            primary: true
        )

        service.characteristics = [
            data,
            control
        ]

        manager.removeAllServices()
        manager.add(service)
    }

    // MARK: - Serviço adicionado

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: Error?
    ) {

        if let error {
            onStatus?("Erro: \(error.localizedDescription)")
            return
        }

        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [
                BridgeProtocol.serviceUUID
            ],
            CBAdvertisementDataLocalNameKey: "Ponte"
        ])
    }

    // MARK: - Anúncio Bluetooth

    func peripheralManagerDidStartAdvertising(
        _ peripheral: CBPeripheralManager,
        error: Error?
    ) {

        onStatus?(
            error == nil
                ? "Aguardando o relógio…"
                : "Erro ao anunciar"
        )
    }

    // MARK: - Inscrição do relógio

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {

        guard characteristic.uuid == BridgeProtocol.controlUUID else {
            return
        }

        hasControlSubscriber = true

        onStatus?("Relógio conectado")

        sendPendingAcks()
    }

    // MARK: - Cancelamento da inscrição

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {

        guard characteristic.uuid == BridgeProtocol.controlUUID else {
            return
        }

        hasControlSubscriber = false

        onStatus?("Relógio desconectado")
    }

    // MARK: - Recebimento de dados

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {

        guard let firstRequest = requests.first else {
            return
        }

        // Validar todas as solicitações.
        for request in requests {

            guard request.characteristic.uuid == BridgeProtocol.dataUUID else {
                peripheral.respond(
                    to: firstRequest,
                    withResult: .writeNotPermitted
                )
                return
            }

            guard let value = request.value, !value.isEmpty else {
                peripheral.respond(
                    to: firstRequest,
                    withResult: .invalidAttributeValueLength
                )
                return
            }
        }

        // Reconstruir as mensagens recebidas.
        var completedMessages: [ReassembledMessage] = []

        for request in requests {

            guard let value = request.value else {
                continue
            }

            if let message = reassembler.feed(value) {
                completedMessages.append(message)
            }
        }

        // Responder uma única vez ao callback BLE.
        peripheral.respond(
            to: firstRequest,
            withResult: .success
        )

        // Entregar mensagens completas ao aplicativo.
        for message in completedMessages {
            onMessage?(message)
        }
    }

    // MARK: - Envio de ACK ao relógio

    func sendAck(for id: UInt16) {

        guard let data = try? JSONSerialization.data(
            withJSONObject: [
                "ack": Int(id)
            ]
        ) else {
            return
        }

        pendingAcks.append(data)

        sendPendingAcks()
    }

    // MARK: - Processamento da fila de ACK

    private func sendPendingAcks() {

        guard let control = controlChar,
              manager.state == .poweredOn,
              hasControlSubscriber else {
            return
        }

        while let data = pendingAcks.first {

            let sent = manager.updateValue(
                data,
                for: control,
                onSubscribedCentrals: nil
            )

            guard sent else {
                return
            }

            pendingAcks.removeFirst()
        }
    }

    // MARK: - Bluetooth pronto para enviar notificações

    func peripheralManagerIsReady(
        toUpdateSubscribers peripheral: CBPeripheralManager
    ) {

        sendPendingAcks()
    }
}
