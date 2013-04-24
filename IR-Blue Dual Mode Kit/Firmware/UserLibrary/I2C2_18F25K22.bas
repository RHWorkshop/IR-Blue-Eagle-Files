'*****************************************************************************
'*  Name    : I2C2 Library                                                   *
'*  Author  : David John Barker                                              *
'*  Notice  : Copyright (c) 2006 Mecanique                                   *
'*          : All Rights Reserved                                            *
'*  Date    : 05/04/06                                                       *
'*  Notes   : 1.1 Added 'WaitForWrite()' routine                             *
'*          : 1.0 Initial release                                            *
'*****************************************************************************
Module I2C2

Include "system.bas"

// map registers to SSP(x)
#if _mssp < 2
   #error _device + " does not support second MSSP"
   
// has more than one SSP module...   
#else
Dim                           // -> MSSP2
   SSPControl1 As SSP2CON1,   //    as SSP2CON1
   SSPControl2 As SSP2CON2,   //    as SSP2CON2
   SSPStatus As SSP2STAT,     //    as SSP2STAT
   SSPBuffer As SSP2BUF,      //    as SSP2BUF
   SSPAddress As SSP2ADD,     //    as SSP2ADD
   SCL As PORTB.1,            //    as PORTD.6
   SDA As PORTB.2             //    as PORTD.5
#endif

// SSPSTAT bitnames, master mode only...
Public Dim
   SMP As SSPStatus.7,     // slew rate control bit
   CKE As SSPStatus.6,     // SMBus select
   P As SSPStatus.4,       // stop bit
   S As SSPStatus.3,       // start bit
   RW As SSPStatus.2,      // transmit in progress
   BF As SSPStatus.0       // buffer full (receive and transmit)    

// SSPCON1 bitnames, master mode only...
Public Dim
   WCOL As SSPControl1.7,  // collision detect
   SSPOV As SSPControl1.6, // receive overflow
   SSPEN As SSPControl1.5, // synchronous receive enable
   
   // synchronous mode select bits, %1000 for master mode
   SSPM3 As SSPControl1.3, 
   SSPM2 As SSPControl1.2, 
   SSPM1 As SSPControl1.1, 
   SSPM0 As SSPControl1.0 

// SSPCON2 bitnames, master mode only...
Public Dim
   ACKSTAT As SSPControl2.6, // acknowledge status bit
   ACKDT As SSPControl2.5,   // acknowledge data bit
   ACKEN As SSPControl2.4,   // acknowledge sequence enable bit
   RCEN As SSPControl2.3,    // receive enable bit
   PEN As SSPControl2.2,     // stop condition enable bit
   RSEN As SSPControl2.1,    // repeated start condition enabled bit
   SEN As SSPControl2.0      // start condition enabled  
   
// I2C constants...
Const FOSC = _clock * 1000000
Public Const 
   I2C_SLEW_OFF = $C0,                      // slew rate disabled for 100kHz mode 
   I2C_SLEW_ON = $00,                       // slew rate enabled for 400kHz mode
   I2C_100_KHZ = FOSC / (100000 * 4) - 1,   // 100 KHz
   I2C_400_KHZ = FOSC / (400000 * 4) - 1,   // 400 KHz
   I2C_1000_KHZ = FOSC / (1000000 * 4) - 1, // 1 MHz
   I2C_ACKNOWLEDGE = 0,                     // acknowledge data bit (acknowledge)
   I2C_NOT_ACKNOWLEDGE = 1                  // acknowledge data bit (NOT acknowledge)

// local helper aliases...   
Dim
   BufferIsFull As SSPStatus.Booleans(0),       // BF as boolean
   AckEnabled As SSPControl2.Booleans(4),       // ACKEN as boolean
   ReceiveEnabled As SSPControl2.Booleans(3),   // RCEN as boolean
   StopEnabled As SSPControl2.Booleans(2),      // PEN as boolean
   RestartEnabled As SSPControl2.Booleans(1),   // RSEN as boolean
   StartEnabled As SSPControl2.Booleans(0)      // SEN as boolean

// public boolean alias...
Public Dim
   NotAcknowledged As SSPControl2.Booleans(6)  // ACKSTAT as boolean
{
****************************************************************************
* Name    : Initialize                                                     *
* Purpose : Initialize SSP module for I2C bus                              *
****************************************************************************
}         
Public Sub Initialize(pBaudrate As Byte = I2C_100_KHZ, pSlew As Byte = I2C_SLEW_OFF)
  SSPAddress = pBaudrate     // set baudrate
  SSPStatus = pSlew          // POR state, optional slew
  SSPControl2 = $00          // POR state
  Input(SCL)                 // set SCL (clock pin) to input
  Input(SDA)                 // set SDA (data pin) to input
  SSPControl1 = $28          // master mode, enable synchronous serial port
End Sub
{
****************************************************************************
* Name    : IsIdle                                                         *
* Purpose : Returns the current I2C idle state                             *
****************************************************************************
}         
Public Function IsIdle() As Boolean
   Result = (SSPControl2 And $1F) = 0 And (RW = 0)
End Function
{
****************************************************************************
* Name    : WaitForIdle                                                    *
* Purpose : Wait until the I2C bus is in an idle state                     *
****************************************************************************
}         
Public Sub WaitForIdle()
   Repeat
      ClrWDT
   Until IsIdle
End Sub
{
****************************************************************************
* Name    : Start                                                          *
* Purpose : Send an I2C bus start condition                                *
****************************************************************************
}         
Public Sub Start()
   WaitForIdle
   StartEnabled = true
   While StartEnabled
   Wend
End Sub
{
****************************************************************************
* Name    : Stop                                                           *
* Purpose : Send an I2C bus stop condition                                 *
****************************************************************************
}         
Public Sub Stop()
  WaitForIdle
  StopEnabled = true
  While StopEnabled
  Wend
End Sub
{
****************************************************************************
* Name    : Restart                                                        *
* Purpose : Send an I2C bus restart condition                              *
****************************************************************************
}         
Public Sub Restart()
   WaitForIdle
   RestartEnabled = true
   While RestartEnabled
   Wend
End Sub
{
****************************************************************************
* Name    : Acknowledge                                                    *
* Purpose : Initiate I2C acknowledge                                       *
*         : pAck = 1, NOT acknowledge                                      *
*         : pAck = 0, acknowledge                                          *
****************************************************************************
}         
Public Sub Acknowledge(pAck As Bit = I2C_ACKNOWLEDGE)
  WaitForIdle
  ACKDT = pAck
  AckEnabled = true
  While AckEnabled
  Wend
End Sub
{
****************************************************************************
* Name    : ReadByte (OVERLOAD)                                            *
* Purpose : Read a single byte from the I2C bus                            *
****************************************************************************
}         
Public Function ReadByte() As Byte
  WaitForIdle
  ReceiveEnabled = true
  Repeat
  Until BufferIsFull
  Result = SSPBuffer
End Function
{
****************************************************************************
* Name    : ReadByte (OVERLOAD)                                            *
* Purpose : Read a single byte from the I2C bus, with Acknowledge          *
****************************************************************************
}         
Public Function ReadByte(pAck As Bit) As Byte
  WaitForIdle
  ReceiveEnabled = true
  Repeat
  Until BufferIsFull
  Result = SSPBuffer
  Acknowledge(pAck)
End Function
{
****************************************************************************
* Name    : WriteByte                                                      *
* Purpose : Write a single byte to the I2C bus                             *
****************************************************************************
}         
Public Sub WriteByte(pData As Byte)
   WaitForIdle
   SSPBuffer = pData
   While BufferIsFull
   Wend
End Sub
{
****************************************************************************
* Name    : WaitForWrite                                                   *
* Purpose : Wait until write sequence has completed                        *
****************************************************************************
}         
Public Sub WaitForWrite(pControl As Byte)
   WaitForIdle
   Start
   WriteByte(pControl)
   WaitForIdle
   While NotAcknowledged 
      Restart
      WriteByte(pControl)
      WaitForIdle
   Wend
   Stop
End Sub
