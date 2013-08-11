 specified by <paramref name="lookupId" /> and removes it from the queue.
                MessageLookupAction.First: Receives the first message in the queue and removes it from the queue. The <paramref name="lookupId" /> parameter must be set to 0.
                MessageLookupAction.Last: Receives the last message in the queue and removes it from the queue. The <paramref name="lookupId" /> parameter must be set to 0.
                </param>
      <param name="lookupId">
                    The <see cref="P:System.Messaging.Message.LookupId" /> of the message to receive, or 0. 0 is used when accessing the first or last message in the queue. 
                </param>
      <param name="transactionType">
                    One of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> values, describing the type of transaction context to associate with the message.
                </param>
      <exception cref="T:System.PlatformNotSupportedException">
                    MSMQ 3.0 is not installed.
                </exception>
      <exception cref="T:System.InvalidOperationException">
                    The message with the specified <paramref name="lookupId" /> could not be found. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <exception cref="T:System.ComponentModel.InvalidEnumArgumentException">
                    The <paramref name="action" /> parameter is not one of the <see cref="T:System.Messaging.MessageLookupAction" /> members.
                
                    -or- 
                
                    The <paramref name="transactionType" /> parameter is not one of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> members.
                </exception>
    </member>
    <member name="E:System.Messaging.MessageQueue.ReceiveCompleted">
      <summary>
                    Occurs when a message has been removed from the queue. This event is raised by the asynchronous operation, <see cref="M:System.Messaging.MessageQueue.BeginReceive" />.
                </summary>
    </member>
    <member name="M:System.Messaging.MessageQueue.Refresh">
      <summary>
                    Refreshes the properties presented by the <see cref="T:System.Messaging.MessageQueue" /> to reflect the current state of the resource.
                </summary>
    </member>
    <member name="M:System.Messaging.MessageQueue.ResetPermissions">
      <summary>
                    Resets the permission list to the operating system's default values. Removes any queue permissions you have appended to the default list.
                </summary>
      <exception cref="T:System.Messaging.MessageQueueException">
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Messaging.MessageQueuePermission, System.Messaging, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.Send(System.Object)">
      <summary>
                    Sends an object to non-transactional queue referenced by this <see cref="T:System.Messaging.MessageQueue" />.
                </summary>
      <param name="obj">
                    The object to send to the queue. 
                </param>
      <exception cref="T:System.Messaging.MessageQueueException">
                    The <see cref="P:System.Messaging.MessageQueue.Path" /> property has not been set.
                
                    -or- 
                
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Security.Permissions.EnvironmentPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.FileIOPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.SecurityPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Flags="UnmanagedCode, ControlEvidence" />
        <IPermission class="System.Messaging.MessageQueuePermission, System.Messaging, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" version="1" Unrestricted="true" />
        <IPermission class="System.Diagnostics.PerformanceCounterPermission, System, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.Send(System.Object,System.Messaging.MessageQueueTransaction)">
      <summary>
                    Sends an object to the transactional queue referenced by this <see cref="T:System.Messaging.MessageQueue" />.
                </summary>
      <param name="obj">
                    The object to send to the queue. 
                </param>
      <param name="transaction">
                    The <see cref="T:System.Messaging.MessageQueueTransaction" /> object. 
                </param>
      <exception cref="T:System.ArgumentNullException">
                    The <paramref name="transaction" /> parameter is null. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    The <see cref="P:System.Messaging.MessageQueue.Path" /> property has not been set.
                
                    -or- 
                
                    The Message Queuing application indicated an incorrect transaction use.
                
                    -or- 
                
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Security.Permissions.EnvironmentPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.FileIOPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.SecurityPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Flags="UnmanagedCode, ControlEvidence" />
        <IPermission class="System.Messaging.MessageQueuePermission, System.Messaging, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" version="1" Unrestricted="true" />
        <IPermission class="System.Diagnostics.PerformanceCounterPermission, System, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.Send(System.Object,System.Messaging.MessageQueueTransactionType)">
      <summary>
                    Sends an object to the queue referenced by this <see cref="T:System.Messaging.MessageQueue" />.
                </summary>
      <param name="obj">
                    The object to send to the queue. 
                </param>
      <param name="transactionType">
                    One of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> values, describing the type of transaction context to associate with the message. 
                </param>
      <exception cref="T:System.ComponentModel.InvalidEnumArgumentException">
                    The <paramref name="transactionType" /> parameter is not one of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> members. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    The <see cref="P:System.Messaging.MessageQueue.Path" /> property has not been set.
                
                    -or- 
                
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Security.Permissions.EnvironmentPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true"