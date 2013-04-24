{
****************************************************************
*  Name    : ISRRX Module                                      *
*  Author  : David John Barker                                 *
*  Notice  : Copyright (c) 2006 Mecanique                      *
*          : All Rights Reserved                               *
*  Date    : 31/03/2006                                        *
*  Version : 1.1                                               *
*  Notes   :                                                   *
*          :                                                   *
****************************************************************
}
Module ISRRX2

// import USART library...
'Include "USART.bas"
Include "USART2_18F25K22.bas"

// set interrupt priority level...
#if IsOption(RX_PRIORITY) And Not (RX_PRIORITY in (ipLow, ipHigh))
   #error RX_PRIORITY, "Invalid option. Priority must be ipHigh or ipLow."
#endif
#option RX_PRIORITY = ipHigh
Const PriorityLevel = RX_PRIORITY

// size of the RX buffer...
#if IsOption(RX_BUFFER_SIZE) And Not (RX_BUFFER_SIZE in (1 to 256))
   #error RX_BUFFER_SIZE, "Invalid option. Buffer size must be between 1 and 256 (bytes)."
#endif
#option RX_BUFFER_SIZE = 64      
Public Const BufferSize = RX_BUFFER_SIZE

Type TEvent = Event()

// local variables and aliases...
Dim 
   FBuffer(BufferSize) As Byte,
   FIndexIn As Byte,
   FIndexOut As Byte,
   FByteRead As Byte,
   FProcessByte As Boolean,
   FMaybeOverrun As Boolean,
   FOnDataEvent As TEvent
 
// public variables and aliases...   
Public Dim   
   USARTOverrun As USART2.Overrun,
   BufferOverrun As Boolean,
   DataByte As FByteRead,
   DataChar As FByteRead.AsChar,
   ProcessByte As FProcessByte

{
****************************************************************************
* Name    : OnRX (PRIVATE)                                                 *
* Purpose : Interrupt Service Routine (ISR) to buffer incoming data        *
****************************************************************************
}
Interrupt OnRX(PriorityLevel)
   Dim FSRSave As Word
   FSRSave = FSR0
   BufferOverrun = FMaybeOverrun
   If Not USART2.Overrun Then
      FByteRead = USART2.RCRegister
      If Not BufferOverrun Then
         FProcessByte = true
         
         // execute handler...
         FOnDataEvent
         
         If FProcessByte Then
            FBuffer(FIndexIn) = FByteRead
            Inc(FIndexIn)
	        If FIndexIn > Bound(FBuffer) Then
               FIndexIn = 0
            EndIf
            FMaybeOverrun = (FIndexIn = FIndexOut) 
         EndIf   
      EndIf
   EndIf	     
   FSR0 = FSRSave
End Interrupt
{
****************************************************************************
* Name    : Initialize                                                     *
* Purpose : Initialize buffering - with optional OnData event handler      *
****************************************************************************
}
Public Sub Initialize(pOnDataEvent As TEvent = 0)
   FOnDataEvent = pOnDataEvent
   FIndexIn = 0
   FIndexOut = 0
   FMaybeOverrun = false
   BufferOverrun = false
   USART2.ClearOverrun
   #if RX_PRIORITY = ipLow
   USART2.RCIPHigh = false
   #endif
   USART2.RCIEnable = true
   Enable(OnRX)
End Sub
{
****************************************************************************
* Name    : Reset                                                          *
* Purpose : Reset module                                                   *
****************************************************************************
}
Public Sub Reset()
   Disable(OnRX)
   Initialize(FOnDataEvent)
End Sub	  
{
****************************************************************************
* Name    : Start                                                          *
* Purpose : Start interrupt handling                                       *
****************************************************************************
}
Public Sub Start()
   Enable(OnRX)
End Sub
{
****************************************************************************
* Name    : Stop                                                           *
* Purpose : Stop interrupt handling                                        *
****************************************************************************
}
Public Sub Stop()
   Disable(OnRX)
End Sub
{
****************************************************************************
* Name    : DataAvailable                                                  *
* Purpose : Check to see if there is data in the buffer                    *
****************************************************************************
}
Public Function DataAvailable() As Boolean
'   Disable(OnRX)
   Result = FIndexIn <> FIndexOut
'   Enable(OnRX)
End Function
{
****************************************************************************
* Name    : Overrun                                                        *
* Purpose : Returns true if RC register or buffer has overrun, false       *
*         : otherwise                                                      *
****************************************************************************
}
Public Function Overrun() As Boolean
   Result = USART2.Overrun Or BufferOverrun
End Function
{
****************************************************************************
* Name    : GetByte (PRIVATE)                                              *
* Purpose : Get a single byte from the buffer                              *
****************************************************************************
}
Function GetByte() As Byte
   FMaybeOverrun = false
   Result = FBuffer(FIndexOut)
   Inc(FIndexOut)
   If FIndexOut > Bound(FBuffer) Then
      FIndexOut = 0
   EndIf   
End Function
{
****************************************************************************
* Name    : ReadByte                                                       *
* Purpose : Read a single byte from the buffer                             *
****************************************************************************
}
Public Function ReadByte() As Byte
   Disable(OnRX)
   Result = GetByte
   Enable(OnRX)
End Function
{
****************************************************************************
* Name    : ReadWord                                                       *
* Purpose : Read a word from the buffer                                    *
****************************************************************************
}
Public Function ReadWord() As Word
   Disable(OnRX)
   Result.Bytes(0) = GetByte
   Result.Bytes(1) = GetByte
   Enable(OnRX)
End Function
{
****************************************************************************
* Name    : ReadLongWord                                                   *
* Purpose : Read a long word from the buffer                               *
****************************************************************************
}
Public Function ReadLongWord() As LongWord
   Disable(OnRX)
   Result.Bytes(0) = GetByte
   Result.Bytes(1) = GetByte
   Result.Bytes(2) = GetByte
   Result.Bytes(3) = GetByte
   Enable(OnRX)
End Function
{
****************************************************************************
* Name    : ReadFloat                                                      *
* Purpose : Read a floating point number from the buffer                   *
****************************************************************************
}
Public Function ReadFloat() As Float
   Disable(OnRX)
   Result.Bytes(0) = GetByte
   Result.Bytes(1) = GetByte
   Result.Bytes(2) = GetByte
   Result.Bytes(3) = GetByte
   Enable(OnRX)
End Function
{
****************************************************************************
* Name    : ReadStr                                                        *
* Purpose : Read a string from the buffer. Optional parameter pTerminator  *
*         : to specify the input string terminator character. The function *
*         : returns the number of characters read                          *
****************************************************************************
}
Public Function ReadStr(ByRef pText As String, pTerminator As Char = null) As Byte
   Dim Ch As Char
   Dim Text As POSTINC0
   
   Disable(OnRX)
   FSR0 = AddressOf(pText)
   Result = 0
   Repeat
      Ch = GetByte
      If Ch <> pTerminator Then
         Text = Ch
         Inc(Result)
      EndIf   
   Until Ch = pTerminator
   Text = 0
   Enable(OnRX)
End Function


	       
