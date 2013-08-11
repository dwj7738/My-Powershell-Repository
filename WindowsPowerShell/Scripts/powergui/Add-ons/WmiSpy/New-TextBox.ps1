ermission class="System.Diagnostics.PerformanceCounterPermission, System, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.ReceiveById(System.String,System.TimeSpan,System.Messaging.MessageQueueTransaction)">
      <summary>
                    Receives the message that matches the given identifier (from a transactional queue) and waits until either a message with the specified identifier is available in the queue or the time-out expires.
                </summary>
      <returns>
                    The <see cref="T:System.Messaging.Message" /> whose <see cref="P:System.Messaging.Message.Id" /> property matches the <paramref name="id" /> parameter passed in.
                </returns>
      <param name="id">
                    The <see cref="P:System.Messaging.Message.Id" /> of the message to receive. 
                </param>
      <param name="timeout">
                    A <see cref="T:System.TimeSpan" /> that indicates the time to wait until a new message is available for inspection. 
                </param>
      <param name="transaction">
                    The <see cref="T:System.Messaging.MessageQueueTransaction" /> object. 
                </param>
      <exception cref="T:System.ArgumentNullException">
                    The <paramref name="id" /> parameter is null.
                
                    -or- 
                
                    The <paramref name="transaction" /> parameter is null. 
                </exception>
      <exception cref="T:System.ArgumentException">
                    The value specified for the <paramref name="timeout" /> parameter is not valid, possibly <paramref name="timeout" /> is less than <see cref="F:System.TimeSpan.Zero" /> or greater than <see cref="F:System.Messaging.MessageQueue.InfiniteTimeout" />. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    A message with the specified <paramref name="id" /> did not arrive in the queue before the time-out expired.
                
                    -or- 
                
                    The queue is non-transactional.
                
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
    <member name="M:System.Messaging.MessageQueue.ReceiveById(System.String,System.TimeSpan,System.Messaging.MessageQueueTransactionType)">
      <summary>
                    Receives the message that matches the given identifier and waits until either a message with the specified identifier is available in the queue or the time-out expires.
                </summary>
      <returns>
                    The <see cref="T:System.Messaging.Message" /> whose <see cref="P:System.Messaging.Message.Id" /> property matches the <paramref name="id" /> parameter passed in.
                </returns>
      <param name="id">
                    The <see cref="P:System.Messaging.Message.Id" /> of the message to receive. 
                </param>
      <param name="timeout">
                    A <see cref="T:System.TimeSpan" /> that indicates the time to wait until a new message is available for inspection. 
                </param>
      <param name="transactionType">
                    One of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> values, describing the type of transaction context to associate with the message. 
                </param>
      <exception cref="T:System.ArgumentNullException">
                    The <paramref name="id" /> parameter is null. 
                </exception>
      <exception cref="T:System.ArgumentException">
                    The value specified for the <paramref name="timeout" /> parameter is not valid, possibly <paramref name="timeout" /> is less than <see cref="F:System.TimeSpan.Zero" /> or greater than <see cref="F:System.Messaging.MessageQueue.InfiniteTimeout" />. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    A message with the specified <paramref name="id" /> did not arrive in the queue before the time-out expired.
                
                    -or- 
                
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <exception cref="T:System.ComponentModel.InvalidEnumArgumentException">
                    The <paramref name="transactionType" /> parameter is not one of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> members. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Security.Permissions.EnvironmentPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.FileIOPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.SecurityPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Flags="UnmanagedCode, ControlEvidence" />
        <IPermission class="System.Messaging.MessageQueuePermission, System.Messaging, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" version="1" Unrestricted="true" />
        <IPermission class="System.Diagnostics.PerformanceCounterPermission, System, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.ReceiveByLookupId(System.Int64)">
      <summary>
                    Introduced in MSMQ 3.0. Receives the message that matches the given lookup identifier from a non-transactional queue.
                </summary>
      <returns>
                    The <see cref="T:System.Messaging.Message" /> whose <see cref="P:System.Messaging.Message.LookupId" /> property matches the <paramref name="lookupId" /> parameter passed in.
                </returns>
      <param name="lookupId">
                    The <see cref="P:System.Messaging.Message.LookupId" /> of the message to receive. 
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
    </member>
    <member name="M:System.Messaging.MessageQueue.ReceiveByLookupId(System.Messaging.MessageLookupAction,System.Int64,System.Messaging.MessageQueueTransaction)">
      <summary>
                    Introduced in MSMQ 3.0. Receives a specific message from a transactional queue. The message can be specified by a lookup identifier or by its position at the front or end of the queue.
                </summary>
      <returns>
                    The <see cref="T:System.Messaging.Message" /> specified by the <paramref name="lookupId" /> and <paramref name="action" /> parameters passed in.
                </returns>
      <param name="action">
                    One of the <see cref="T:System.Messaging.MessageLookupAction" /> values, specifying how the message is read in the queue. Specify one of the following:
                MessageLookupAction.Current: Receives the message specified by <paramref name="lookupId" /> and removes it from the queue.
                MessageLookupAction.Next: Receives the message following the message specified by <paramref name="look