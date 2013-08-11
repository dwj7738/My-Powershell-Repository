Add-Type -TypeDefinition @"
using System;
using System.Net;
using System.Runtime.InteropServices;

    public class NetworkUtil
    {
        [DllImport("iphlpapi.dll", SetLastError = true)]
        static extern uint GetExtendedTcpTable(IntPtr pTcpTable, ref int dwOutBufLen, bool sort, int ipVersion, TCP_TABLE_CLASS tblClass, int reserved);
        [DllImport("iphlpapi.dll", SetLastError = true)]
        static extern uint GetExtendedUdpTable(IntPtr pUdpTable, ref int dwOutBufLen, bool sort, int ipVersion, UDP_TABLE_CLASS tblClass, int reserved);
        [StructLayout(LayoutKind.Sequential)]
        public struct MIB_TCPROW_OWNER_PID
        {
            public uint dwState;
            public uint dwLocalAddr;
            public uint dwLocalPort;
            public uint dwRemoteAddr;
            public uint dwRemotePort;
            public uint dwOwningPid;
        }
        [StructLayout(LayoutKind.Sequential)]
        public struct MIB_UDPROW_OWNER_PID
        {
            public uint dwLocalAddr;
            public uint dwLocalPort;
            public uint dwOwningPid;
        }
        [StructLayout(LayoutKind.Sequential)]
        public struct MIB_TCPTABLE_OWNER_PID
        {
            public uint dwNumEntries;
            MIB_TCPROW_OWNER_PID table;
        }
        [StructLayout(LayoutKind.Sequential)]
        public struct MIB_UDPTABLE_OWNER_PID
        {
            public uint dwNumEntries;
            MIB_UDPROW_OWNER_PID table;
        }
        enum TCP_TABLE_CLASS
        {
            TCP_TABLE_BASIC_LISTENER,
            TCP_TABLE_BASIC_CONNECTIONS,
            TCP_TABLE_BASIC_ALL,
            TCP_TABLE_OWNER_PID_LISTENER,
            TCP_TABLE_OWNER_PID_CONNECTIONS,
            TCP_TABLE_OWNER_PID_ALL,
            TCP_TABLE_OWNER_MODULE_LISTENER,
            TCP_TABLE_OWNER_MODULE_CONNECTIONS,
            TCP_TABLE_OWNER_MODULE_ALL
        }
        enum UDP_TABLE_CLASS
        {
            UDP_TABLE_BASIC,
            UDP_TABLE_OWNER_PID,
            UDP_OWNER_MODULE
        }

        public static Connection[] GetTCP()
        {

            MIB_TCPROW_OWNER_PID[] tTable;
            int AF_INET = 2;
            int buffSize = 0;

            uint ret = GetExtendedTcpTable(IntPtr.Zero, ref buffSize, true, AF_INET, TCP_TABLE_CLASS.TCP_TABLE_OWNER_PID_ALL, 0);
            IntPtr buffTable = Marshal.AllocHGlobal(buffSize);

            try
            {
                ret = GetExtendedTcpTable(buffTable, ref buffSize, true, AF_INET, TCP_TABLE_CLASS.TCP_TABLE_OWNER_PID_ALL, 0);
                if (ret != 0)
                {
                    Connection[] con = new Connection[0];
                    return con;
                }

                MIB_TCPTABLE_OWNER_PID tab = (MIB_TCPTABLE_OWNER_PID)Marshal.PtrToStructure(buffTable, typeof(MIB_TCPTABLE_OWNER_PID));
                IntPtr rowPtr = (IntPtr)((long)buffTable + Marshal.SizeOf(tab.dwNumEntries));
                tTable = new MIB_TCPROW_OWNER_PID[tab.dwNumEntries];

                for (int i = 0; i < tab.dwNumEntries; i++)
                {
                    MIB_TCPROW_OWNER_PID tcpRow = (MIB_TCPROW_OWNER_PID)Marshal.PtrToStructure(rowPtr, typeof(MIB_TCPROW_OWNER_PID));
                    tTable[i] = tcpRow;
                    rowPtr = (IntPtr)((long)rowPtr + Marshal.SizeOf(tcpRow));   // next entry
                }
            }
            finally
            { Marshal.FreeHGlobal(buffTable);}
            Connection[] cons = new Connection[tTable.Length];

            for(int i=0; i < tTable.Length; i++)
            {
                IPAddress localip = new IPAddress(BitConverter.GetBytes(tTable[i].dwLocalAddr));
                IPAddress remoteip = new IPAddress(BitConverter.GetBytes(tTable[i].dwRemoteAddr));
                byte[] barray = BitConverter.GetBytes(tTable[i].dwLocalPort);
                int localport = (barray[0] * 256) + barray[1];
                barray = BitConverter.GetBytes(tTable[i].dwRemotePort);
                int remoteport = (barray[0] * 256) + barray[1];
                string state;
                switch (tTable[i].dwState)
                {
                    case 1:
                        state = "Closed";
                        break;
                    case 2:
                        state = "LISTENING";
                        break;
                    case 3:
                        state = "SYN SENT";
                        break;
                    case 4:
                        state = "SYN RECEIVED";
                        break;
                    case 5:
                        state = "ESTABLISHED";
                        break;
                    case 6:
                        state = "FINSIHED 1";
                        break;
                    case 7:
                        state = "FINISHED 2";
                        break;
                    case 8:
                        state = "CLOSE WAIT";
                        break;
                    case 9:
                        state = "CLOSING";
                        break;
                    case 10:
                        state = "LAST ACKNOWLEDGE";
                        break;
                    case 11:
                        state = "TIME WAIT";
                        break;
                    case 12:
                        state = "DELETE TCB";
                        break;
                    default:
                        state = "UNKNOWN";
                        break;
                }
                Connection tmp = new Connection(localip, localport, remoteip, remoteport, (int)tTable[i].dwOwningPid, state);
                cons[i] = (tmp);
            }
            return cons;
        }
        public static Connection[] GetUDP()
        {
            MIB_UDPROW_OWNER_PID[] tTable;
            int AF_INET = 2; // IP_v4
            int buffSize = 0;

            uint ret = GetExtendedUdpTable(IntPtr.Zero, ref buffSize, true, AF_INET, UDP_TABLE_CLASS.UDP_TABLE_OWNER_PID, 0);
            IntPtr buffTable = Marshal.AllocHGlobal(buffSize);

            try
            {
                ret = GetExtendedUdpTable(buffTable, ref buffSize, true, AF_INET, UDP_TABLE_CLASS.UDP_TABLE_OWNER_PID, 0);
                if (ret != 0)
                {//none found
                    Connection[] con = new Connection[0];
                    return con;
                }
                MIB_UDPTABLE_OWNER_PID tab = (MIB_UDPTABLE_OWNER_PID)Marshal.PtrToStructure(buffTable, typeof(MIB_UDPTABLE_OWNER_PID));
                IntPtr rowPtr = (IntPtr)((long)buffTable + Marshal.SizeOf(tab.dwNumEntries));
                tTable = new MIB_UDPROW_OWNER_PID[tab.dwNumEntries];
               
                for (int i = 0; i < tab.dwNumEntries; i++)
                {
                    MIB_UDPROW_OWNER_PID udprow = (MIB_UDPROW_OWNER_PID)Marshal.PtrToStructure(rowPtr, typeof(MIB_UDPROW_OWNER_PID));
                    tTable[i] = udprow;
                    rowPtr = (IntPtr)((long)rowPtr + Marshal.SizeOf(udprow));
                }
            }
            finally
            { Marshal.FreeHGlobal(buffTable);}
            Connection[] cons = new Connection[tTable.Length];

            for (int i = 0; i < tTable.Length; i++)
            {
                IPAddress localip = new IPAddress(BitConverter.GetBytes(tTable[i].dwLocalAddr));
                byte[] barray = BitConverter.GetBytes(tTable[i].dwLocalPort);
                int localport = (barray[0] * 256) + barray[1];
                Connection tmp = new Connection(localip, localport, (int)tTable[i].dwOwningPid);
                cons[i] = tmp;
            }
            return cons;
        }
    }
    public class Connection
    {
        private IPAddress _localip, _remoteip;
        private int _localport, _remoteport, _pid;
        private string _state, _remotehost, _proto;
        public Connection(IPAddress Local, int LocalPort, IPAddress Remote, int RemotePort, int PID, string State)
        {
            _proto = "TCP";
            _localip = Local;
            _remoteip = Remote;
            _localport = LocalPort;
            _remoteport = RemotePort;
            _pid = PID;
            _state = State;
        }
        public Connection(IPAddress Local, int LocalPort, int PID)
        {
             _proto = "UDP";
            _localip = Local;
            _localport = LocalPort;
            _pid = PID;
        }
        public IPAddress LocalIP { get{ return _localip;}}
        public IPAddress RemoteIP{ get{return _remoteip;}}
        public int LocalPort{ get{return _localport;}}
        public int RemotePort{ get { return _remoteport; }}
        public int PID{ get { return _pid; }}
        public string State{ get { return _state; }}
        public string Protocol{get { return _proto; }}
        public string RemoteHostName
        {
            get {
                if (_remotehost == null)
                    _remotehost = Dns.GetHostEntry(_remoteip).HostName;
                return _remotehost;
            }
        }
        public string PIDName{ get { return (System.Diagnostics.Process.GetProcessById(_pid)).ProcessName; } }
    }
"@

function Get-NetStat
{
    PARAM([switch]$TCPonly, [switch]$UDPonly)
        if(!$UDPonly)
        {$tcp = [NetworkUtil]::GetTCP()}
        if(!$tcponly)
        {$udp = [NetworkUtil]::GetUDP()}
        $results = $tcp + $udp
        return $results
} 