
import Foundation
import Combine

// MARK: - Gerenciamento de notificações

final class NotificationManager: ObservableObject {

    @Published private(set) var notifications: [AppNotification] = []

    // MARK: - Adicionar notificação

    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
    }

    // MARK: - Marcar como lida

    func markAsRead(_ notificationID: UUID) {
        guard let index = notifications.firstIndex(where: {
            $0.id == notificationID
        }) else {
            return
        }

        notifications[index].isRead = true
    }

    // MARK: - Remover notificação

    func removeNotification(_ notificationID: UUID) {
        notifications.removeAll {
            $0.id == notificationID
        }
    }

    // MARK: - Limpar notificações

    func clearNotifications() {
        notifications.removeAll()
    }

    // MARK: - Filtrar por aplicativo

    func notifications(for appIdentifier: String) -> [AppNotification] {
        notifications.filter {
            $0.appIdentifier == appIdentifier
        }
    }

    // MARK: - Contagem de não lidas

    var unreadCount: Int {
        notifications.filter {
            !$0.isRead
        }.count
    }
}
