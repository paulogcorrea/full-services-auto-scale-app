import { Injectable, inject } from '@angular/core';
import { MatSnackBar, MatSnackBarConfig } from '@angular/material/snack-bar';
import { BehaviorSubject, Observable } from 'rxjs';
import { Notification } from '../models';

@Injectable({
  providedIn: 'root'
})
export class NotificationService {
  private snackBar = inject(MatSnackBar);
  private notificationsSubject = new BehaviorSubject<Notification[]>([]);

  public notifications$: Observable<Notification[]> = this.notificationsSubject.asObservable();

  private defaultConfig: MatSnackBarConfig = {
    duration: 5000,
    horizontalPosition: 'end',
    verticalPosition: 'top'
  };

  showSuccess(message: string, title: string = 'Success'): void {
    this.show(message, title, 'success');
    this.snackBar.open(message, 'Close', {
      ...this.defaultConfig,
      panelClass: ['success-snackbar']
    });
  }

  showError(message: string, title: string = 'Error'): void {
    this.show(message, title, 'error');
    this.snackBar.open(message, 'Close', {
      ...this.defaultConfig,
      duration: 8000,
      panelClass: ['error-snackbar']
    });
  }

  showWarning(message: string, title: string = 'Warning'): void {
    this.show(message, title, 'warning');
    this.snackBar.open(message, 'Close', {
      ...this.defaultConfig,
      panelClass: ['warning-snackbar']
    });
  }

  showInfo(message: string, title: string = 'Info'): void {
    this.show(message, title, 'info');
    this.snackBar.open(message, 'Close', {
      ...this.defaultConfig,
      panelClass: ['info-snackbar']
    });
  }

  private show(message: string, title: string, type: 'success' | 'error' | 'warning' | 'info'): void {
    const notification: Notification = {
      id: this.generateId(),
      type,
      title,
      message,
      timestamp: new Date(),
      read: false
    };

    const currentNotifications = this.notificationsSubject.value;
    this.notificationsSubject.next([notification, ...currentNotifications]);
  }

  markAsRead(id: string): void {
    const notifications = this.notificationsSubject.value.map(n => 
      n.id === id ? { ...n, read: true } : n
    );
    this.notificationsSubject.next(notifications);
  }

  markAllAsRead(): void {
    const notifications = this.notificationsSubject.value.map(n => ({ ...n, read: true }));
    this.notificationsSubject.next(notifications);
  }

  removeNotification(id: string): void {
    const notifications = this.notificationsSubject.value.filter(n => n.id !== id);
    this.notificationsSubject.next(notifications);
  }

  clearAll(): void {
    this.notificationsSubject.next([]);
  }

  getUnreadCount(): number {
    return this.notificationsSubject.value.filter(n => !n.read).length;
  }

  private generateId(): string {
    return Math.random().toString(36).substr(2, 9);
  }
}
