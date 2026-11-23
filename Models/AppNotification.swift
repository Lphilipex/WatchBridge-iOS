
import Foundation

// MARK: - Notificação recebida de um aplicativo

struct AppNotification: Identifiable {

    // Identificação
    let id: UUID

    // Aplicativo de origem
    let appName: String
    let appIdentifier: String

    // Conteúdo da notificação
    let title: String
    let message: String

    // Recebimento
    let receivedAt: Date

    // Estado da notificação
    var isRead: Bool

    // Indica se a origem disponibilizou uma ação de resposta
    let canReply: Bool

    init(
        id: UUID = UUID(),
        appName: String,
        appIdentifier: String,
        title: String,
        message: String,
        receivedAt: Date = Date(),
        isRead: Bool = false,
        canReply: Bool = false
    ) {
        self.id = id
        self.appName = appName
        self.appIdentifier = appIdentifier
        self.title = title
        self.message = message
        self.receivedAt = receivedAt
        self.isRead = isRead
        self.canReply = canReply
    }
}
