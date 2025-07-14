import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable, tap, catchError, throwError, map } from 'rxjs';
import { environment } from '@environments/environment';
import { 
  User, 
  LoginRequest, 
  LoginResponse, 
  RegisterRequest,
  UserRole 
} from '../models';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);

  private currentUserSubject = new BehaviorSubject<User | null>(null);
  private tokenSubject = new BehaviorSubject<string | null>(null);

  public currentUser$ = this.currentUserSubject.asObservable();
  public token$ = this.tokenSubject.asObservable();
  public isAuthenticated$ = this.currentUser$.pipe(map(user => !!user));
  public isAdmin$ = this.currentUser$.pipe(map(user => user?.role === 'admin'));

  constructor() {
    this.loadStoredAuth();
  }

  login(credentials: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${environment.apiUrl}/auth/login`, credentials)
      .pipe(
        tap(response => {
          this.setAuthData(response);
        }),
        catchError(error => {
          return throwError(() => error);
        })
      );
  }

  register(userData: RegisterRequest): Observable<{ message: string; user: User }> {
    return this.http.post<{ message: string; user: User }>(
      `${environment.apiUrl}/auth/register`, 
      userData
    );
  }

  refreshToken(): Observable<LoginResponse> {
    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      return throwError(() => new Error('No refresh token available'));
    }

    return this.http.post<LoginResponse>(`${environment.apiUrl}/auth/refresh`, {
      refresh_token: refreshToken
    }).pipe(
      tap(response => {
        this.setAuthData(response);
      }),
      catchError(error => {
        this.logout();
        return throwError(() => error);
      })
    );
  }

  logout(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('user');
    this.currentUserSubject.next(null);
    this.tokenSubject.next(null);
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  getToken(): string | null {
    return this.tokenSubject.value;
  }

  getRefreshToken(): string | null {
    return localStorage.getItem('refresh_token');
  }

  isAuthenticated(): boolean {
    return !!this.getCurrentUser() && !!this.getToken();
  }

  isAdmin(): boolean {
    const user = this.getCurrentUser();
    return user?.role === 'admin';
  }

  isTenantAdmin(): boolean {
    const user = this.getCurrentUser();
    return user?.role === 'tenant_admin' || user?.role === 'admin';
  }

  hasRole(role: UserRole): boolean {
    const user = this.getCurrentUser();
    return user?.role === role;
  }

  updateCurrentUser(user: User): void {
    this.currentUserSubject.next(user);
    localStorage.setItem('user', JSON.stringify(user));
  }

  private setAuthData(response: LoginResponse): void {
    localStorage.setItem('token', response.token);
    localStorage.setItem('refresh_token', response.refresh_token);
    localStorage.setItem('user', JSON.stringify(response.user));
    
    this.currentUserSubject.next(response.user);
    this.tokenSubject.next(response.token);
  }

  private loadStoredAuth(): void {
    const token = localStorage.getItem('token');
    const userStr = localStorage.getItem('user');

    if (token && userStr) {
      try {
        const user = JSON.parse(userStr) as User;
        this.currentUserSubject.next(user);
        this.tokenSubject.next(token);
      } catch (error) {
        console.error('Error parsing stored user data:', error);
        this.logout();
      }
    }
  }

  private isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const expirationTime = payload.exp * 1000;
      return Date.now() >= expirationTime;
    } catch (error) {
      return true;
    }
  }

  checkTokenExpiration(): void {
    const token = this.getToken();
    if (token && this.isTokenExpired(token)) {
      this.refreshToken().subscribe({
        error: () => {
          this.logout();
          this.router.navigate(['/auth/login']);
        }
      });
    }
  }

  updateProfile(profileData: { firstName: string; lastName: string; email: string }): Observable<User> {
    return this.http.put<User>(`${environment.apiUrl}/users/me`, profileData)
      .pipe(
        tap(user => {
          this.updateCurrentUser(user);
        }),
        catchError(error => {
          return throwError(() => error);
        })
      );
  }
}
