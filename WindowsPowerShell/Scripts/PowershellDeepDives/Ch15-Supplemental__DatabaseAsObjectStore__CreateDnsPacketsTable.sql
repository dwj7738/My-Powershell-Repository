USE [DnsLogDb]
GO

/****** Object:  Table [dbo].[DnsPackets]    Script Date: 10/1/2012 7:36:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DnsPackets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QueryFqdn] [nchar](100) NULL,
	[RemoteIpAddr] [nchar](100) NULL,
	[DateTime] [datetime2](7) NULL
) ON [PRIMARY]

GO

