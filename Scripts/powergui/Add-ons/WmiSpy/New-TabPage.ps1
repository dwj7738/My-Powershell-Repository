

/* this ALWAYS GENERATED file contains the definitions for the interfaces */


 /* File created by MIDL compiler version 7.00.0555 */
/* Compiler settings for textstor.idl:
    Oicf, W1, Zp8, env=Win32 (32b run), target_arch=X86 7.00.0555 
    protocol : dce , ms_ext, c_ext, robust
    error checks: allocation ref bounds_check enum stub_data 
    VC __declspec() decoration level: 
         __declspec(uuid()), __declspec(selectany), __declspec(novtable)
         DECLSPEC_UUID(), MIDL_INTERFACE()
*/
/* @@MIDL_FILE_HEADING(  ) */

#pragma warning( disable: 4049 )  /* more than 64k source lines */


/* verify that the <rpcndr.h> version is high enough to compile this file*/
#ifndef __REQUIRED_RPCNDR_H_VERSION__
#define __REQUIRED_RPCNDR_H_VERSION__ 500
#endif

/* verify that the <rpcsal.h> version is high enough to compile this file*/
#ifndef __REQUIRED_RPCSAL_H_VERSION__
#define __REQUIRED_RPCSAL_H_VERSION__ 100
#endif

#include "rpc.h"
#include "rpcndr.h"

#ifndef __RPCNDR_H_VERSION__
#error this stub requires an updated version of <rpcndr.h>
#endif // __RPCNDR_H_VERSION__

#ifndef COM_NO_WINDOWS_H
#include "windows.h"
#include "ole2.h"
#endif /*COM_NO_WINDOWS_H*/

#ifndef __textstor_h__
#define __textstor_h__

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
#pragma once
#endif

/* Forward Declarations */ 

#ifndef __ITextStoreACP_FWD_DEFINED__
#define __ITextStoreACP_FWD_DEFINED__
typedef interface ITextStoreACP ITextStoreACP;
#endif 	/* __ITextStoreACP_FWD_DEFINED__ */


#ifndef __ITextStoreACPSink_FWD_DEFINED__
#define __ITextStoreACPSink_FWD_DEFINED__
typedef interface ITextStoreACPSink ITextStoreACPSink;
#endif 	/* __ITextStoreACPSink_FWD_DEFINED__ */


#ifndef __IAnchor_FWD_DEFINED__
#define __IAnchor_FWD_DEFINED__
typedef interface IAnchor IAnchor;
#endif 	/* __IAnchor_FWD_DEFINED__ */


#ifndef __ITextStoreAnchor_FWD_DEFINED__
#define __ITextStoreAnchor_FWD_DEFINED__
typedef interface ITextStoreAnchor ITextStoreAnchor;
#endif 	/* __ITextStoreAnchor_FWD_DEFINED__ */


#ifndef __ITextStoreAnchorSink_FWD_DEFINED__
#define __ITextStoreAnchorSink_FWD_DEFINED__
typedef interface ITextStoreAnchorSink ITextStoreAnchorSink;
#endif 	/* __ITextStoreAnchorSink_FWD_DEFINED__ */


/* header files for imported files */
#include "oaidl.h"

#ifdef __cplusplus
extern "C"{
#endif 


/* interface __MIDL_itf_textstor_0000_0000 */
/* [local] */ 


DEFINE_GUID (GUID_TS_SERVICE_DATAOBJECT, 0x6086fbb5, 0xe225, 0x46ce, 0xa7, 0x70, 0xc1, 0xbb, 0xd3, 0xe0, 0x5d, 0x7b);
DEFINE_GUID (GUID_TS_SERVICE_ACCESSIBLE, 0xf9786200, 0xa5bf, 0x4a0f, 0x8c, 0x24, 0xfb, 0x16, 0xf5, 0xd1, 0xaa, 0xbb);
DEFINE_GUID (GUID_TS_SERVICE_ACTIVEX,    0xea937a50, 0xc9a6, 0x4b7d, 0x89, 0x4a, 0x49, 0xd9, 0x9b, 0x78, 0x48, 0x34);
#define TS_E_INVALIDPOS      MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0200)
#define TS_E_NOLOCK          MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0201)
#define TS_E_NOOBJECT        MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0202)
#define TS_E_NOSERVICE       MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0203)
#define TS_E_NOINTERFACE     MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0204)
#define TS_E_NOSELECTION     MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0205)
#define TS_E_NOLAYOUT        MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0206)
#define TS_E_INVALIDPOINT    MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0207)
#define TS_E_SYNCHRONOUS     MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0208)
#define TS_E_READONLY        MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x0209)
#define TS_E_FORMAT          MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 0x020a)
#define TS_S_ASYNC           MAKE_HRESULT(SEVERITY_SUCCESS, FACILITY_ITF, 0x0300)
#define	TS_AS_TEXT_CHANGE	( 0x1 )

#define	TS_AS_SEL_CHANGE	( 0x2 )

#define	TS_AS_LAYOUT_CHANGE	( 0x4 )

#define	TS_AS_ATTR_CHANGE	( 0x8 )

#define	TS_AS_STATUS_CHANGE	( 0x10 )

#define	TS_AS_ALL_SINKS	( ( ( ( ( TS_AS_TEXT_CHANGE | TS_AS_SEL_CHANGE )  | TS_AS_LAYOUT_CHANGE )  | TS_AS_ATTR_CHANGE )  | TS_AS_STATUS_CHANGE )  )

#define	TS_LF_SYNC	( 0x1 )

#define	TS_LF_READ	( 0x2 )

#define	TS_LF_READWRITE	( 0x6 )

#define	TS_SD_READONLY	( 0x1 )

#define	TS_SD_LOADING	( 0x2 )

#define	TS_SS_DISJOINTSEL	( 0x1 )

#define	TS_SS_REGIONS	( 0x2 )

#define	TS_SS_TRANSITORY	( 0x4 )

#define	TS_SS_NOHIDDENTEXT	( 0x8 )

#define	TS_SD_MASKALL	( ( TS_SD_READONLY | TS_SD_LOADING )  )

#define	TS_ST_CORRECTION	( 0x1 )

#define	TS_IE_CORRECTION	( 0x1 )

#define	TS_IE_COMPOSITION	( 0x2 )

#define	TS_TC_CORRECTION	( 0x1 )

#define	TS_IAS_NOQUERY	( 0x1 )

#define	TS_IAS_QUERYONLY	( 0x2 )

typedef /* [uuid] */  DECLSPEC_UUID("fec4f516-c503-45b1-a5fd-7a3d8ab07049") struct TS_STATUS
    {
    DWORD dwDynamicFlags;
    DWORD dwStaticFlags;
    } 	TS_STATUS;

typedef /* [uuid] */  DECLSPEC_UUID("f3181bd6-bcf0-41d3-a81c-474b17ec38fb") struct TS_TEXTCHANGE
    {
    LONG acpStart;
    LONG acpOldEnd;
    LONG acpNewEnd;
    } 	TS_TEXTCHANGE;

typedef /* [public][public][public][public][public][public][public][uuid] */  DECLSPEC_UUID("05fcf85b-5e9c-4c3e-ab71-29471d4f38e7") 
enum __MIDL___MIDL_itf_textstor_0000_0000_0001
    {	TS_AE_NONE	= 0,
	TS_AE_START	= 1,
	TS_AE_END	= 2
    } 	TsActiveSelEnd;

typedef /* [uuid] */  DECLSPEC_UUID("7ecc3ffa-8f73-4d91-98ed-76f8ac5b1600") struct TS_SELECTIONSTYLE
    {
    TsActiveSelEnd ase;
    BOOL fInterimChar;
    } 	TS_SELECTIONSTYLE;

typedef /* [uuid] */  DECLSPEC_UUID("c4b9c33b-8a0d-4426-bebe-d444a4701fe9") struct TS_SELECTION_ACP
    {
    LONG acpStart;
    LONG acpEnd;
    TS_SELECTIONSTYLE style;
    } 	TS_SELECTION_ACP;

typedef /* [uuid] */  DECLSPEC_UUID("b03413d2-0723-4c4e-9e08-2e9c1ff3772b") struct TS_SELECTION_ANCHOR
    {
    IAnchor *paStart;
    IAnchor *paEnd;
    TS_SELECTIONSTYLE style;
    } 	TS_SELECTION_ANCHOR;

#define	TS_DEFAULT_SELECTION	( ( ULONG  )-1 )

#define	GXFPF_ROUND_NEAREST	( 0x1 )

#define	GXFPF_NEAREST	( 0x2 )

#define	TS_CHAR_EMBEDDED	( 0xfffc )

#define	TS_CHAR_REGION	( 0 )

#define	TS_CHAR_REPLACEMENT	( 0xfffd )

typedef /* [uuid] */  DECLSPEC_UUID("ef3457d9-8446-49a7-a9e6-b50d9d5f3fd9") GUID TS_ATTRID;

typedef /* [uuid] */  DECLSPEC_UUID("2cc2b33f-1174-4507-b8d9-5bc0eb37c197") struct TS_ATTRVAL
    {
    TS_ATTRID idAttr;
    DWORD dwOverlapId;
    VARIANT varValue;
    } 	TS_ATTRVAL;

#define	TS_ATTR_FIND_BACKWARDS	( 0x1 )

#define	TS_ATTR_FIND_WANT_OFFSET	( 0x2 )

#define	TS_ATTR_FIND_UPDATESTART	( 0x4 )

#define	TS_ATTR_FIND_WANT_VALUE	( 0x8 )

#define	TS_ATTR_FIND_WANT_END	( 0x10 )

#define	TS_ATTR_FIND_HIDDEN	( 0x20 )

typedef /* [uuid] */  DECLSPEC_UUID("1faf509e-44c1-458e-950a-38a96705a62b") DWORD TsViewCookie;

#define	TS_VCOOKIE_NUL	( 0xffffffff )

typedef /* [public][public][public][uuid] */  DECLSPEC_UUID("7899d7c4-5f07-493c-a89a-fac8e777f476") 
enum __MIDL___MIDL_itf_textstor_0000_0000_0002
    {	TS_LC_CREATE	= 0,
	TS_LC_CHANGE	= 1,
	TS_LC_DESTROY	= 2
    } 	TsLayoutCode;

typedef /* [public][public][public][uuid] */  DECLSPEC_UUID("033b0df0-f193-4170-b47b-141afc247878") 
enum __MIDL___MIDL_itf_textstor_0000_0000_0003
    {	TS_RT_PLAIN	= 0,
	TS_RT_HIDDEN	= ( TS_RT_PLAIN + 1 ) ,
	TS_RT_OPAQUE	= ( TS_RT_HIDDEN + 1 ) 
    } 	TsRunType;

typedef /* [uuid] */  DECLSPEC_UUID("a6231949-37c5-4b74-a24e-2a26c327201d") struct TS_RUNINFO
    {
    ULONG uCount;
    TsRunType type;
    } 	TS_RUNINFO;



extern RPC_IF_HANDLE __MIDL_itf_textstor_0000_0000_v0_0_c_ifspec;
extern RPC_IF_HANDLE __MIDL_itf_textstor_0000_0000_v0_0_s_ifspec;

#ifndef __ITextStoreACP_INTERFACE_DEFINED__
#define __ITextStoreACP_INTERFACE_DEFINED__

/* interface ITextStoreACP */
/* [unique][uuid][object] */ 


EXTERN_C const IID IID_ITextStoreACP;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("28888fe3-c2a0-483a-a3ea-8cb1ce51ff3d")
    ITextStoreACP : public IUnknown
    {
    public:
        virtual HRESULT STDMET
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbrclQpXFlS3SrK/sfiyNEpyi
# DAagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBrBArCdDpgmwMnM
# j6IKT2bO4EV7MA0GCSqGSIb3DQEBAQUABIIBAJtSta/1bxFEunj4nxnxwt1O62YD
# H56yMPp0/s81ee+Ze9X4kGCNAwc8i4k7mETzABH74OxD7mtHTKlrXDZ3DMZ+gu7Z
# WZFmwmuKbqWxaC1YLXd+jW5y8MOk8zRRhavwPAMmdcrY2N2fPpq7NqQE89Ah4Dco
# 8XLX1rRldcl+zo2I6OVO8/yehncs9WMDMWpUbjLIT+11IAnFd9wpNshxrC/oTzbJ
# 15/3VthZcBX1hd4f8gLDL+ciAh9mieRui82XThMrKgCG/sZvdvWwQ0ffeWsD1SML
# LYZkDktLI0nCuwzGfG9EyrjVaGqwDGj8efAj813rs9Y+xENSYUL0NlczDKQ=
# SIG # End signature block
