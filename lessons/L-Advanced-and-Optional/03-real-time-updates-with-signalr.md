# Lesson 3: Real-Time Updates with SignalR

Many modern applications require real-time communication with the server. Instead of the client constantly polling the server for updates (which is inefficient), the server can **push** updates to the client as they happen. WebSockets are the standard technology for this, and **SignalR** is a popular framework (especially in the .NET ecosystem) that makes working with WebSockets easy.

This lesson covers how to integrate the SignalR client into an Angular application to receive and react to real-time messages from the server.

- **Resource:** [Using real-time data in Angular with SignalR](https://blog.logrocket.com/using-real-time-data-angular-signalr/)
- **Resource:** [Integrate SignalR with Angular](https://pradhanadi.medium.com/integrate-signalr-with-angular-ee71a4508434)

## How SignalR Works

SignalR uses a concept called a **Hub** on the server. The server-side Hub has methods that can be called by clients, and it can also push messages to clients. The client (our Angular app) connects to this Hub.

-   **Client-to-Server:** The client can invoke methods on the Hub (e.g., `hubConnection.invoke('SendMessage', 'Hello')`).
-   **Server-to-Client:** The Hub can push messages to clients by invoking a method name that the client is listening for (e.g., `hubConnection.on('ReceiveMessage', ...)`)

## 1. Setting up the SignalR Client

First, you need to install the official Microsoft SignalR client package.

```bash
npm install @microsoft/signalr
```

## 2. Creating a `SignalrService`

It's a best practice to encapsulate all the SignalR connection logic within a single injectable service. This service will manage the connection and expose the incoming messages as RxJS `Observable`s.

```typescript
// signalr.service.ts
import { Injectable } from '@angular/core';
import * as signalR from '@microsoft/signalr';
import { Observable, Subject } from 'rxjs';
import { environment } from 'src/environments/environment';

@Injectable({ providedIn: 'root' })
export class SignalrService {
  private hubConnection: signalR.HubConnection;

  // Use Subjects to expose server events as Observables
  private messageReceived$ = new Subject<any>();
  private statusUpdated$ = new Subject<any>();

  constructor() {
    this.hubConnection = new signalR.HubConnectionBuilder()
      .withUrl(`${environment.apiUrl}/myHub`) // URL to your SignalR Hub
      .withAutomaticReconnect()
      .build();
  }

  // Call this method to start the connection
  public startConnection = () => {
    this.hubConnection
      .start()
      .then(() => {
        console.log('SignalR connection started');
        this.registerServerEvents();
      })
      .catch(err => console.error('Error while starting SignalR connection: ' + err));
  }

  // Register listeners for server-sent events
  private registerServerEvents(): void {
    // Listen for the "ReceiveMessage" event from the server
    this.hubConnection.on('ReceiveMessage', (data) => {
      this.messageReceived$.next(data);
    });

    // Listen for the "StatusUpdated" event from the server
    this.hubConnection.on('StatusUpdated', (data) => {
      this.statusUpdated$.next(data);
    });
  }

  // Expose the events as public Observables
  public get onMessageReceived(): Observable<any> {
    return this.messageReceived$.asObservable();
  }

  public get onStatusUpdated(): Observable<any> {
    return this.statusUpdated$.asObservable();
  }

  // You can also add methods to invoke server-side Hub methods
  public sendMessage(message: string): Promise<void> {
    return this.hubConnection.invoke('SendMessageOnHub', message);
  }
}
```

## 3. Starting the Connection

The connection should be started when the application initializes, typically in the `AppComponent` or triggered by an `APP_INITIALIZER`.

```typescript
// app.component.ts
import { Component, OnInit, inject } from '@angular/core';
import { SignalrService } from './signalr.service';

@Component({ /* ... */ })
export class AppComponent implements OnInit {
  private signalrService = inject(SignalrService);

  ngOnInit() {
    this.signalrService.startConnection();
  }
}
```

## 4. Integrating with State Management

Now, other services or components can inject the `SignalrService` and subscribe to the event observables. This is particularly powerful when integrated with a state management solution like NgRx.

An NgRx Effect can listen to these observables and dispatch actions in response to server-pushed events.

### Example: An NgRx Effect

```typescript
// live-updates.effects.ts
import { Injectable, inject } from '@angular/core';
import { Actions, createEffect } from '@ngrx/effects';
import { map } from 'rxjs/operators';
import { SignalrService } from './signalr.service';
import { LiveUpdatesApiActions } from './live-updates.actions';

@Injectable()
export class LiveUpdatesEffects {
  private actions$ = inject(Actions);
  private signalrService = inject(SignalrService);

  // When the SignalR service receives a new message,
  // dispatch an action to add it to the store.
  messageReceived$ = createEffect(() =>
    this.signalrService.onMessageReceived.pipe(
      map(message => LiveUpdatesApiActions.messageReceived({ message }))
    )
  );

  // When the SignalR service receives a status update,
  // dispatch an action to update the relevant entity in the store.
  statusUpdated$ = createEffect(() =>
    this.signalrService.onStatusUpdated.pipe(
      map(statusUpdate => LiveUpdatesApiActions.statusUpdated({ update: statusUpdate }))
    )
  );
}
```
The corresponding reducers would then handle these actions to update the state, and the UI would reactively update, showing the real-time data to the user.

By encapsulating the SignalR logic in a service and exposing events as observables, you can create a clean, reactive, and maintainable integration that brings real-time functionality to your Angular application.