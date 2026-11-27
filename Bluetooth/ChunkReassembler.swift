
import Foundation

// MARK: - Mensagem reconstruída

struct ReassembledMessage {

    let id: UInt16
    let data: Data
}

// MARK: - Reconstrução de pacotes BLE

final class ChunkReassembler {

    // MARK: - Configurações

    private let messageTimeout: TimeInterval = 30

    // MARK: - Estado da mensagem atual

    private var currentMessageID: UInt16?
    private var expectedChunkCount: UInt16?

    private var chunks: [UInt16: Data] = [:]
    private var totalBytes = 0

    private var lastChunkReceivedAt: TimeInterval?

    // MARK: - Recebimento de fragmentos

    func feed(_ packet: Data) -> ReassembledMessage? {

        let bytes = [UInt8](packet)

        // Validar tamanho mínimo do cabeçalho.
        guard bytes.count > BridgeProtocol.packetHeaderLength else {
        return nil
        }

        // Validar identificação e versão.
        guard bytes[0] == BridgeProtocol.packetMagic[0],
              bytes[1] == BridgeProtocol.packetMagic[1],
              bytes[2] == BridgeProtocol.packetVersion else {
            return nil
        }

        // Extrair identificador da mensagem.
        let messageID =
            (UInt16(bytes[3]) << 8) | UInt16(bytes[4])

        // Extrair índice do fragmento.
        let chunkIndex =
            (UInt16(bytes[5]) << 8) | UInt16(bytes[6])

        // Extrair quantidade total de fragmentos.
        let chunkCount =
            (UInt16(bytes[7]) << 8) | UInt16(bytes[8])

        // Validar os índices.
        guard chunkCount > 0,
              chunkCount <= BridgeProtocol.maximumChunkCount,
              chunkIndex < chunkCount else {
            return nil
        }

        // Verificar se a mensagem atual expirou.
        let currentTime = ProcessInfo.processInfo.systemUptime

        if let lastReceived = lastChunkReceivedAt,
           currentTime - lastReceived >= messageTimeout {

            reset()
        }

        // Extrair os dados do fragmento.
        let payload = Data(
            bytes.dropFirst(BridgeProtocol.packetHeaderLength)
        )

        // Iniciar uma nova mensagem quando necessário.
        if currentMessageID == nil || currentMessageID != messageID {

            // Uma mensagem nova precisa começar pelo fragmento zero.
            guard chunkIndex == 0 else {
                return nil
            }

            reset()

            currentMessageID = messageID
            expectedChunkCount = chunkCount
        }

        // Validar a quantidade de fragmentos.
        guard expectedChunkCount == chunkCount else {

            reset()

            return nil
        }

        // Verificar fragmentos duplicados.
        if let existingChunk = chunks[chunkIndex] {

            if existingChunk != payload {
                reset()
            }

            return nil
        }

        // Impedir que a mensagem ultrapasse o tamanho permitido.
        guard totalBytes + payload.count <= BridgeProtocol.maximumMessageSize else {

            reset()

            return nil
        }

        // Armazenar o fragmento recebido.
        chunks[chunkIndex] = payload
        totalBytes += payload.count

        // Atualizar o tempo do último fragmento válido.
        lastChunkReceivedAt = currentTime

        // Aguardar todos os fragmentos.
        guard chunks.count == Int(chunkCount) else {
            return nil
        }

        // Reconstruir a mensagem completa.
        var completeData = Data()

        for index in 0..<Int(chunkCount) {

            guard let chunk = chunks[UInt16(index)] else {

                reset()

                return nil
            }

            completeData.append(chunk)
        }

        // Criar a mensagem reconstruída.
        let message = ReassembledMessage(
            id: messageID,
            data: completeData
        )

        // Limpar o estado após a conclusão.
        reset()

        return message
    }

    // MARK: - Limpeza do estado

    func reset() {

        currentMessageID = nil
        expectedChunkCount = nil

        chunks.removeAll()

        totalBytes = 0

        lastChunkReceivedAt = nil
    }
}
