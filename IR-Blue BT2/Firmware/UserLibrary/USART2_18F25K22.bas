{
*****************************************************************************
*  Name    : USART2 Library                                                 *
*  Author  : David John Barker                                              *
*  Notice  : Copyright (c) 2003 Mecanique                                   *
*          : All Rights Reserved                                            *
*  Date    : 21/01/06                                                       *
*  Version : 1.5 Reworked for silicon error                                 *
*  Version : 1.4 Removed TXIF from WriteItem(Str) and replaced with PIR1, 4 *
*  Version : 1.3 Added support for USART_BRG16                              *
*  Notes   : 1.2 Supports second USART module                               *
*****************************************************************************
}
Module USART2

Include "system.bas"

// calculate clock...
Const FOSC = _clock * 1000000

// low speed or high speed (BRGH)...
#if IsOption(USART2_BRGH) And Not (USART2_BRGH in (true, false))
   #error USART2_BRGH, "Invalid option. BRGH must be TRUE or FALSE."
#endif
#option USART2_BRGH = true   
#if USART2_BRGH = true   
Const USART_MODE = $24
#else
Const USART_MODE = $20
#endif   

// 8 bit or 16 bit (BRG16 only supported with EUSART modules)...
#if IsOption(USART2_BRG16) And Not (USART2_BRG16 in (true, false))
   #error USART2_BRG16, "Invalid option. BRG16 must be TRUE or FALSE."
#endif
#option USART2_BRG16 = false
#if Not USART2_BRG16 And Not USART2_BRGH     // BRG16 = 0, BRGH = 0
Const FMULT = 64
#elseif USART2_BRG16 And Not USART2_BRGH     // BRG16 = 1, BRGH = 0
Const FMULT = 16
#elseif Not USART2_BRG16 And USART2_BRGH     // BRG16 = 0, BRGH = 1
Const FMULT = 16
#else                                      // BRG16 = 1, BRGH = 1
Const FMULT = 4
#endif  

// map registers to USART(x)
#if _usart < 2
   #error _device + " does not support second USART"
  
// MCU has more than one USART...
#else 
Public Dim                         // -> USART2
   #if USART2_BRG16
   SPBRGRegister As SPBRG2.AsWord,
   BRG16 As BAUDCON2.3,
   #else
   SPBRGRegister As SPBRG2,
   #endif
   RCRegister As RCREG2,           //    as RCREG2
   TXRegister As TXREG2,           //    as TXREG2
   RCStatus As RCSTA2,             //    as TXSTA2
   TXStatus As TXSTA2,             //    as TXSTA2
   RCInput As TRISB.Booleans(7),    
   TXInput As TRISB.Booleans(6) 
#endif
 
Dim                                // -> USART2
   PIR As PIR3,                    //    as PIR3 
   PIE As PIE3,                    //    as PIE3
   IPR As IPR3                     //    as IPR3

// public baudrate constants...
#if USART2_BRG16
Public Const
   br300 As Word   = FOSC / (FMULT * (300 + 1)) - 1 + 0.5,
   br600 As Word   = FOSC / (FMULT * (600 + 1)) - 1 + 0.5,
   br1200 As Word  = FOSC / (FMULT * (1200 + 1)) - 1 + 0.5,
   br2400 As Word  = FOSC / (FMULT * (2400 + 1)) - 1 + 0.5,
   br4800 As Word  = FOSC / (FMULT * (4800 + 1)) - 1 + 0.5,
   br9600 As Word  = FOSC / (FMULT * (9600 + 1)) - 1 + 0.5,
   br19200 As Word = FOSC / (FMULT * (19200 + 1)) - 1 + 0.5,
   br38400 As Word = FOSC / (FMULT * (38400 + 1)) - 1 + 0.5,
   br57600 As Word = FOSC / (FMULT * (57600 + 1)) - 1 + 0.5,
   br115200 As Word = FOSC / (FMULT * (115200 + 1)) - 1 + 0.5
#else
Public Const
   br300 As Byte   = FOSC / (FMULT * (300 + 1)) - 1 + 0.5,
   br600 As Byte   = FOSC / (FMULT * (600 + 1)) - 1 + 0.5,
   br1200 As Byte  = FOSC / (FMULT * (1200 + 1)) - 1 + 0.5,
   br2400 As Byte  = FOSC / (FMULT * (2400 + 1)) - 1 + 0.5,
   br4800 As Byte  = FOSC / (FMULT * (4800 + 1)) - 1 + 0.5,
   br9600 As Byte  = FOSC / (FMULT * (9600 + 1)) - 1 + 0.5,
   br19200 As Byte = FOSC / (FMULT * (19200 + 1)) - 1 + 0.5,
   br38400 As Byte = FOSC / (FMULT * (38400 + 1)) - 1 + 0.5,
   br57600 As Byte = FOSC / (FMULT * (57600 + 1)) - 1 + 0.5,
   br115200 As Byte = FOSC / (FMULT * (115200 + 1)) - 1 + 0.5
#endif
  
// alias public bitnames to TXSTA(x)...
Public Dim
   CSRC As TXStatus.7,
   TX9 As TXStatus.6,
   TXEN As TXStatus.5,
   SYNC As TXStatus.4,
   BRGH As TXStatus.2,
   TRMT As TXStatus.1,
   TX9D As TXStatus.0

// alias public bitnames to RCSTA(x)...
Public Dim
   SPEN As RCStatus.7,
   RX9 As RCStatus.6,
   SREN As RCStatus.5,
   CREN As RCStatus.4,
   ADDEN As RCStatus.3,
   FERR As RCStatus.2,
   OERR As RCStatus.1,
   RX9D As RCStatus.0
   
// alias public interrupt flags...
Public Dim
   RCIF As PIR.5,  // receive buffer full 
   TXIF As PIR.4,  // transmit buffer empty 
   RCIE As PIE.5,  // receive interrupt enable
   TXIE As PIE.4,  // transmit interrupt enable
   RCIP As IPR.5,  // receive interrupt priority
   TXIP As IPR.4   // transmit interrupt priority
   
// public boolean flags...
Public Dim  
   DataAvailable As PIR.Booleans(5),         // RCIF
   ReadyToSend As PIR.Booleans(4),           // TXIF
   ContinousReceive As RCStatus.Booleans(4), // CREN
   Overrun As RCStatus.Booleans(1),          // OERR
   FrameError As RCStatus.Booleans(2),       // FERR
   RCIEnable As PIE.Booleans(5),             // RCIE
   TXIEnable As PIE.Booleans(4),             // TXIE
   RCIPHigh As IPR.Booleans(5),              // RCIP
   TXIPHigh As IPR.Booleans(4)               // TXIP

Public Dim
   ReadTerminator As Char                    // read string terminator
{
****************************************************************************
* Name    : SetBaudrate                                                    *
* Purpose : Sets the hardware USART baudrate                               *
*         : Pass SPBRG constant, as defined above. For example, br115200   *
****************************************************************************
}
Public Sub SetBaudrate(pSPBRG As SPBRGRegister = br19200)
   RCStatus = $90         // serial port enable, continuous receive
   RCInput = true         // receive pin is input
   TXInput = false        // transmit pin is output
   TXStatus = USART_MODE  // high or low speed
   #if USART2_BRG16
   BRG16 = 1
   #endif
End Sub
{
****************************************************************************
* Name    : ClearOverrun                                                   *
* Purpose : Clear USART overrun error by resetting receive flag            *
****************************************************************************
}
Public Sub ClearOverrun()
   If Overrun Then
      CREN = 0  // disable continuous receive
      CREN = 1  // enable continous receive
   EndIf   
End Sub
{
****************************************************************************
* Name    : ReadByte                                                       *
* Purpose : Read a byte from the hardware USART                            *
*         : Waits for USART data, return byte in RCREG(x)                  *
****************************************************************************
}
Public Function ReadByte() As RCRegister
   Repeat
      ClrWDT
   Until DataAvailable
End Function
{
****************************************************************************
* Name    : ReadBoolean                                                    *
* Purpose : Read a boolean from the hardware USART                         *
****************************************************************************
}
Public Function ReadBoolean() As Boolean
   Result = Boolean(ReadByte)
End Function 
{
****************************************************************************
* Name    : ReadWord                                                       *
* Purpose : Read a word from the hardware USART                            *
****************************************************************************
}
Public Function ReadWord() As Word
   Result.Bytes(0) = ReadByte
   Result.Bytes(1) = ReadByte
End Function  
{
****************************************************************************
* Name    : ReadLongWord                                                   *
* Purpose : Read a long word from the hardware USART                       *
****************************************************************************
}
Public Function ReadLongWord() As LongWord
   Result.Bytes(0) = ReadByte
   Result.Bytes(1) = ReadByte
   Result.Bytes(2) = ReadByte
   Result.Bytes(3) = ReadByte
End Function  
{
****************************************************************************
* Name    : ReadFloat                                                      *
* Purpose : Read a float from the hardware USART                           *
****************************************************************************
}
Public Function ReadFloat() As Float
   Result.Bytes(0) = ReadByte
   Result.Bytes(1) = ReadByte
   Result.Bytes(2) = ReadByte
   Result.Bytes(3) = ReadByte
End Function 
{
****************************************************************************
* Name    : WriteByte                                                      *
* Purpose : Write a byte value to the hardware USART                       *
*         : Wait until ready to send is enabled, then send WREG byte       *
****************************************************************************
}
Public Sub WriteByte(pValue As WREG)
   Repeat
      ClrWDT
   Until ReadyToSend
   TXRegister = WREG
End Sub
{
****************************************************************************
* Name    : WriteBoolean                                                   *
* Purpose : Write a boolean value to the hardware USART                    *
****************************************************************************
}
Public Sub WriteBoolean(pValue As Boolean)
   WriteByte(Byte(pValue))
End Sub
{
****************************************************************************
* Name    : WriteWord                                                      *
* Purpose : Write a word value to the hardware USART                       *
****************************************************************************
}
Public Sub WriteWord(pValue As Word)
   WriteByte(pValue.Bytes(0))
   WriteByte(pValue.Bytes(1))
End Sub
{
****************************************************************************
* Name    : WriteLongWord                                                  *
* Purpose : Write a word value to the hardware USART                       *
****************************************************************************
}
Public Sub WriteLongWord(pValue As LongWord) 
   WriteByte(pValue.Bytes(0))
   WriteByte(pValue.Bytes(1))
   WriteByte(pValue.Bytes(2))
   WriteByte(pValue.Bytes(3))
End Sub
{
****************************************************************************
* Name    : WriteFloat                                                     *
* Purpose : Write a floating point number to the hardware USART            *
****************************************************************************
}
Public Sub WriteFloat(pValue As Float) 
   WriteByte(pValue.Bytes(0))
   WriteByte(pValue.Bytes(1))
   WriteByte(pValue.Bytes(2))
   WriteByte(pValue.Bytes(3))
End Sub
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read a boolean from the hardware USART                         *
****************************************************************************
}
Sub ReadItem(ByRef pValue As Boolean)
   pValue = Boolean(ReadByte)
End Sub 
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read a byte from the hardware USART                            *
****************************************************************************
}
Sub ReadItem(ByRef pValue As Byte)
   pValue = ReadByte
End Sub  
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read a shortint from the hardware USART                        *
****************************************************************************
}
Sub ReadItem(ByRef pValue As ShortInt)
   pValue = ReadByte
End Sub  
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read a word from the hardware USART                            *
****************************************************************************
}
Sub ReadItem(ByRef pValue As Word)
   pValue = ReadWord
End Sub
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read an integer from the hardware USART                        *
****************************************************************************
}
Sub ReadItem(ByRef pValue As Integer)
   pValue = ReadWord
End Sub
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read a long word from the hardware USART                       *
****************************************************************************
}
Sub ReadItem(ByRef pValue As LongWord)
   pValue = ReadLongWord
End Sub
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read a long integer from the hardware USART                    *
****************************************************************************
}
Sub ReadItem(ByRef pValue As LongInt)
   pValue = ReadLongWord
End Sub
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read a floating point number from the hardware USART           *
****************************************************************************
}
Sub ReadItem(ByRef pValue As Float) 
   pValue = ReadFloat
End Sub
{
****************************************************************************
* Name    : ReadItem (OVERLOAD)                                            *
* Purpose : Read a string from the hardware USART. Use ReadTerminator      *
*         : to specify the input string terminator character.              *
*         : 1.5 Reworked for silicon error                                 *
****************************************************************************
}
Sub ReadItem(ByRef pText As String)
   Dim TextPtr As POSTINC0
   Dim TextAddr As FSR0
   Dim Value As Byte
   
   TextAddr = AddressOf(pText)
   Value = ReadByte
   While Value <> Byte(ReadTerminator)
      TextPtr = Value
      Value = ReadByte
   Wend
   TextPtr = null
End Sub
{
****************************************************************************
* Name    : Read (COMPOUND)                                                *
* Purpose : Read an item from the hardware USART                           *
****************************************************************************
}
Public Compound Sub Read(ReadItem)
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write a boolean value to the hardware USART                    *
****************************************************************************
}
Sub WriteItem(pValue As Boolean)
   WriteByte(Byte(pValue))
End Sub
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write a byte value to the hardware USART                       *
****************************************************************************
}
Sub WriteItem(pValue As WREG)
   WriteByte(pValue)
End Sub
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write a short int value to the hardware USART                  *
****************************************************************************
}
Sub WriteItem(pValue As ShortInt)
   WriteByte(pValue)
End Sub
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write a word value to the hardware USART                       *
****************************************************************************
}
Sub WriteItem(pValue As Word) 
   WriteWord(pValue)
End Sub
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write an integer value to the hardware USART                   *
****************************************************************************
}
Sub WriteItem(pValue As Integer) 
   WriteWord(pValue)
End Sub
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write a long word to the hardware USART                        *
****************************************************************************
}
Sub WriteItem(pValue As LongWord) 
   WriteLongWord(pValue)
End Sub
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write a long integer to the hardware USART                     *
****************************************************************************
}
Sub WriteItem(pValue As LongInt) 
   WriteLongWord(pValue)
End Sub
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write a floating point number to the hardware USART            *
****************************************************************************
}
Sub WriteItem(pValue As Float) 
   WriteByte(pValue.Bytes(0))
   WriteByte(pValue.Bytes(1))
   WriteByte(pValue.Bytes(2))
   WriteByte(pValue.Bytes(3))
End Sub
{
****************************************************************************
* Name    : WriteItem (OVERLOAD)                                           *
* Purpose : Write a string value to the hardware USART                     *
****************************************************************************
}
Sub WriteItem(pText As String)
   FSR0 = AddressOf(pText)
   #if WDT
   ASM
     movf  POSTINC0, W
     bz    $ + 12  
     ClrWDT
     btfss PIR, 4
     bra   $ - 4
     movwf TXRegister
     bra   $ - 12
   End ASM
   #else
   ASM
     movf  POSTINC0, W
     bz    $ + 10  
     btfss PIR, 4
     bra   $ - 2
     movwf TXRegister
     bra   $ - 10
  End ASM
  #endif
End Sub
{
****************************************************************************
* Name    : Write (COMPOUND)                                               *
* Purpose : Write an item to the hardware USART                            *
****************************************************************************
}
Public Compound Sub Write(WriteItem)
{
****************************************************************************
* Name    : WaitFor                                                        *
* Purpose : Wait for a byte value to be received                           *
****************************************************************************
}
Public Function WaitFor(pValue As Byte) As Boolean
   result = ReadByte = pValue
End Function
{
****************************************************************************
* Name    : WaitForTimeout                                                 *
* Purpose : Wait for a byte value to be received, with timeout value in    *
*         : milliseconds                                                   *
****************************************************************************
}
Public Function WaitForTimeout(pValue As Byte, pTimeout As Word) As Boolean
   Dim Counter As Byte
   Dim Timeout As Word

   ClearOverrun
   Result = false
   Counter = 10
   Repeat
      Timeout = pTimeout
      While Timeout > 0
         If DataAvailable And (RCRegister = pValue) Then
            Result = true
            Exit
         EndIf   
         DelayUS(100)
         Dec(Timeout)
      Wend
      Dec(Counter)
   Until Counter = 0
End Function
{
****************************************************************************
* Name    : WaitForCount                                                   *
* Purpose : Wait for pAmount bytes to be received. The incoming data is    *
*         : stored in pArray                                               *
****************************************************************************
}
Public Sub WaitForCount(ByRef pArray() As Byte, pCount As Word)
   Dim Index As Word
   ClearOverrun
   Index = 0
   While pCount > 0
      pArray(Index) = ReadByte
      Dec(pCount)
      Inc(Index)
   Wend
End Sub
{
****************************************************************************
* Name    : WaitForStr                                                     *
* Purpose : Wait for a string to be received                               *
****************************************************************************
}
Public Sub WaitForStr(pStr As String)
   Dim Index As Byte

   ClearOverrun
   Index = 0
   While pStr(Index) <> null
      If WaitFor(pStr(Index)) Then
         Inc(Index)
      Else
         Index = 0
      EndIf
   Wend
End Sub
{
****************************************************************************
* Name    : WaitForStrCount                                                *
* Purpose : Wait for pAmount characters to be received. The incoming data  *
*         : is stored in pStr                                              *
****************************************************************************
}
Public Sub WaitForStrCount(ByRef pStr As String, pCount As Word)
   Dim Index As Byte
   ClearOverrun
   Index = 0
   While pCount > 0
      pStr(Index) = ReadByte
      Dec(pCount)
      Inc(Index)
   Wend
   pStr(Index) = null
End Sub
{
****************************************************************************
* Name    : WaitForStrTimeout                                              *
* Purpose : Wait for a string to be received, with timeout value in        *
*         : milliseconds                                                   *
****************************************************************************
}
Public Function WaitForStrTimeout(pStr As String, pTimeout As Word) As Boolean
   Dim Counter, StrIndex As Byte
   Dim Timeout As Word
   Dim Ch As Byte

   ClearOverrun
   Result = false
   StrIndex = 0
   Counter = 10
   Repeat
      Timeout = pTimeout
      While Timeout > 0
         Ch = pStr(StrIndex)
         If Ch = 0 Then
            result = true
            Exit
         ElseIf DataAvailable Then
            If Ch = RCRegister Then
               Inc(StrIndex)
            Else
               StrIndex = 0
            EndIf   
         EndIf
         DelayUS(100)
         Dec(Timeout)
      Wend
      Dec(Counter)
   Until Counter = 0
End Function
{
****************************************************************************
* Name    : DataAvailableTimeout                                           *
* Purpose : Checks to see if a byte value has been received, with          *
*         : timeout in milliseconds                                        *
****************************************************************************
}
Public Function DataAvailableTimeout(pTimeout As Word) As Boolean
   Dim Counter As Byte
   Dim Timeout As Word

   ClearOverrun
   Counter = 10
   Repeat
      Timeout = pTimeout
      While (Timeout > 0) And Not DataAvailable
         DelayUS(100)
         Dec(Timeout)
      Wend
      Dec(Counter)
   Until (Counter = 0) Or DataAvailable
   result = DataAvailable   
End Function
{
****************************************************************************
* Name    : Rep                                                            *
* Purpose : Write a byte value, pAmount times                              *
****************************************************************************
}
Public Sub Rep(pValue, pAmount As Byte)
   While pAmount > 0
      WriteByte(pValue)
      Dec(pAmount)
   Wend   
End Sub
{
****************************************************************************
* Name    : Skip                                                           *
* Purpose : Read pAmount bytes                                             *
****************************************************************************
}
Public Sub Skip(pAmount As Byte)
   Dim Value As Byte
   While pAmount > 0
      Value = ReadByte
      Dec(pAmount)
   Wend   
End Sub

// module initialisation...
ReadTerminator = null 
