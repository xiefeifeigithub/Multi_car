// -- (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
// --
// -- This file contains confidential and proprietary information
// -- of Xilinx, Inc. and is protected under U.S. and 
// -- international copyright and other intellectual property
// -- laws.
// --
// -- DISCLAIMER
// -- This disclaimer is not a license and does not grant any
// -- rights to the materials distributed herewith. Except as
// -- otherwise provided in a valid license issued to you by
// -- Xilinx, and to the maximum extent permitted by applicable
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// -- (2) Xilinx shall not be liable (whether in contract or tort,
// -- including negligence, or under any other theory of
// -- liability) for any loss or damage of any kind or nature
// -- related to, arising under or in connection with these
// -- materials, including for any direct, or any indirect,
// -- special, incidental, or consequential loss or damage
// -- (including loss of data, profits, goodwill, or any type of
// -- loss or damage suffered as a result of any action brought
// -- by a third party) even if such damage or loss was
// -- reasonably foreseeable or Xilinx had been advised of the
// -- possibility of the same.
// --
// -- CRITICAL APPLICATIONS
// -- Xilinx products are not designed or intended to be fail-
// -- safe, or for use in any application requiring fail-safe
// -- performance, such as life-support or safety devices or
// -- systems, Class III medical devices, nuclear facilities,
// -- applications related to the deployment of airbags, or any
// -- other applications that could lead to death, personal
// -- injury, or severe property or environmental damage
// -- (individually and collectively, "Critical
// -- Applications"). Customer assumes the sole risk and
// -- liability of any use of Xilinx products in Critical
// -- Applications, subject only to applicable laws and
// -- regulations governing limitations on product liability.
// --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// -- PART OF THIS FILE AT ALL TIMES.
//-----------------------------------------------------------------------------
//
// File name: crossbar_sasd.v
//
// Description: 
//   This module is a M-master to N-slave AXI axi_crossbar_v2_1_crossbar switch.
//   Single transaction issuing, single arbiter (both W&R), single data pathways.
//   The interface of this module consists of a vectored slave and master interface
//     in which all slots are sized and synchronized to the native width and clock 
//     of the interconnect, and are all AXI4 protocol.
//   All width, clock and protocol conversions are done outside this block, as are
//     any pipeline registers or data FIFOs.
//   This module contains all arbitration, decoders and channel multiplexing logic.
//     It also contains the diagnostic registers and control interface.
//
//--------------------------------------------------------------------------
//
// Structure:
//    crossbar_sasd
//      addr_arbiter_sasd
//        mux_enc
//      addr_decoder
//        comparator_static
//      splitter
//      mux_enc
//      axic_register_slice
//      decerr_slave
//      
//-----------------------------------------------------------------------------
`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_crossbar_v2_1_crossbar_sasd #
  (
   parameter         C_FAMILY                       = "none", 
   parameter integer C_NUM_SLAVE_SLOTS              =   1, 
   parameter integer C_NUM_MASTER_SLOTS             =   1, 
   parameter integer C_NUM_ADDR_RANGES              = 1,
   parameter integer C_AXI_ID_WIDTH                   = 1, 
   parameter integer C_AXI_ADDR_WIDTH                 = 32, 
   parameter integer C_AXI_DATA_WIDTH = 32, 
   parameter integer C_AXI_PROTOCOL                 = 0, 
   parameter [C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*64-1:0] C_M_AXI_BASE_ADDR = {C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*64{1'b1}}, 
   parameter [C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*64-1:0] C_M_AXI_HIGH_ADDR = {C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*64{1'b0}}, 
   parameter [C_NUM_SLAVE_SLOTS*64-1:0] C_S_AXI_BASE_ID = {C_NUM_SLAVE_SLOTS*64{1'b0}},
   parameter [C_NUM_SLAVE_SLOTS*64-1:0] C_S_AXI_HIGH_ID = {C_NUM_SLAVE_SLOTS*64{1'b0}},
   parameter integer C_AXI_SUPPORTS_USER_SIGNALS      = 0,
   parameter integer C_AXI_AWUSER_WIDTH               = 1,
   parameter integer C_AXI_ARUSER_WIDTH               = 1,
   parameter integer C_AXI_WUSER_WIDTH                = 1,
   parameter integer C_AXI_RUSER_WIDTH                = 1,
   parameter integer C_AXI_BUSER_WIDTH                = 1,
   parameter [C_NUM_SLAVE_SLOTS-1:0] C_S_AXI_SUPPORTS_WRITE           = {C_NUM_SLAVE_SLOTS{1'b1}}, 
   parameter [C_NUM_SLAVE_SLOTS-1:0] C_S_AXI_SUPPORTS_READ            = {C_NUM_SLAVE_SLOTS{1'b1}}, 
   parameter [C_NUM_MASTER_SLOTS-1:0] C_M_AXI_SUPPORTS_WRITE           = {C_NUM_MASTER_SLOTS{1'b1}}, 
   parameter [C_NUM_MASTER_SLOTS-1:0] C_M_AXI_SUPPORTS_READ            = {C_NUM_MASTER_SLOTS{1'b1}}, 
   parameter [C_NUM_SLAVE_SLOTS*32-1:0] C_S_AXI_ARB_PRIORITY             = {C_NUM_SLAVE_SLOTS{32'h00000000}},
   parameter [C_NUM_MASTER_SLOTS*32-1:0] C_M_AXI_SECURE                   = {C_NUM_MASTER_SLOTS{32'h00000000}},
   parameter [C_NUM_MASTER_SLOTS*32-1:0] C_M_AXI_ERR_MODE            = {C_NUM_MASTER_SLOTS{32'h00000000}},
   parameter integer C_R_REGISTER               = 0,
   parameter integer C_RANGE_CHECK                    = 0,
   parameter integer C_ADDR_DECODE                    = 0,
   parameter integer C_DEBUG              = 1
   )
  (
   // Global Signals
   input  wire                                                    ACLK,
   input  wire                                                    ARESETN,
   // Slave Interface Write Address Ports
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_AWID,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ADDR_WIDTH-1:0]           S_AXI_AWADDR,
   input  wire [C_NUM_SLAVE_SLOTS*8-1:0]                          S_AXI_AWLEN,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                          S_AXI_AWSIZE,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                          S_AXI_AWBURST,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                          S_AXI_AWLOCK,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          S_AXI_AWCACHE,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                          S_AXI_AWPROT,
//   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          S_AXI_AWREGION,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          S_AXI_AWQOS,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_AWUSER_WIDTH-1:0]         S_AXI_AWUSER,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_AWVALID,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_AWREADY,
   // Slave Interface Write Data Ports
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_WID,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH/8-1:0]   S_AXI_WSTRB,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_WLAST,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_WUSER_WIDTH-1:0]          S_AXI_WUSER,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_WVALID,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_WREADY,
   // Slave Interface Write Response Ports
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_BID,
   output wire [C_NUM_SLAVE_SLOTS*2-1:0]                          S_AXI_BRESP,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_BUSER_WIDTH-1:0]          S_AXI_BUSER,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_BVALID,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_BREADY,
   // Slave Interface Read Address Ports
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_ARID,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ADDR_WIDTH-1:0]           S_AXI_ARADDR,
   input  wire [C_NUM_SLAVE_SLOTS*8-1:0]                          S_AXI_ARLEN,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                          S_AXI_ARSIZE,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                          S_AXI_ARBURST,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                          S_AXI_ARLOCK,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          S_AXI_ARCACHE,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                          S_AXI_ARPROT,
//   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          S_AXI_ARREGION,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          S_AXI_ARQOS,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ARUSER_WIDTH-1:0]         S_AXI_ARUSER,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_ARVALID,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_ARREADY,
   // Slave Interface Read Data Ports
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_RID,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH-1:0]     S_AXI_RDATA,
   output wire [C_NUM_SLAVE_SLOTS*2-1:0]                          S_AXI_RRESP,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_RLAST,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_RUSER_WIDTH-1:0]          S_AXI_RUSER,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_RVALID,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            S_AXI_RREADY,
   // Master Interface Write Address Port
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_AWID,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ADDR_WIDTH-1:0]          M_AXI_AWADDR,
   output wire [C_NUM_MASTER_SLOTS*8-1:0]                         M_AXI_AWLEN,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                         M_AXI_AWSIZE,
   output wire [C_NUM_MASTER_SLOTS*2-1:0]                         M_AXI_AWBURST,
   output wire [C_NUM_MASTER_SLOTS*2-1:0]                         M_AXI_AWLOCK,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         M_AXI_AWCACHE,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                         M_AXI_AWPROT,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         M_AXI_AWREGION,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         M_AXI_AWQOS,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_AWUSER_WIDTH-1:0]        M_AXI_AWUSER,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           M_AXI_AWVALID,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           M_AXI_AWREADY,
   // Master Interface Write Data Ports
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_WID,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH-1:0]    M_AXI_WDATA,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH/8-1:0]  M_AXI_WSTRB,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           M_AXI_WLAST,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_WUSER_WIDTH-1:0]         M_AXI_WUSER,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           M_AXI_WVALID,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           M_AXI_WREADY,
   // Master Interface Write Response Ports
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_BID,  // Unused
   input  wire [C_NUM_MASTER_SLOTS*2-1:0]                         M_AXI_BRESP,
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_BUSER_WIDTH-1:0]         M_AXI_BUSER,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           M_AXI_BVALID,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           M_AXI_BREADY,
   // Master Interface Read Address Port
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_ARID,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ADDR_WIDTH-1:0]          M_AXI_ARADDR,
   output wire [C_NUM_MASTER_SLOTS*8-1:0]                         M_AXI_ARLEN,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                         M_AXI_ARSIZE,
   output wire [/******************************************************************************
*
* Copyright (C) 2011 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/*****************************************************************************/
/**
* @file xl2cc.h
*
* This file contains the address definitions for the PL310 Level-2 Cache
* Controller.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- ---------------------------------------------------
* 1.00a sdm  02/01/10 Initial version
* 3.10a srt 04/18/13 Implemented ARM Erratas. Please refer to file
*		      'xil_errata.h' for errata description
* </pre>
*
* @note
*
* None.
*
******************************************************************************/

#ifndef _XL2CC_H_
#define _XL2CC_H_

#ifdef __cplusplus
extern "C" {
#endif

/************************** Constant Definitions *****************************/
/* L2CC Register Offsets */
#define XPS_L2CC_ID_OFFSET		0x0000U
#define XPS_L2CC_TYPE_OFFSET		0x0004U
#define XPS_L2CC_CNTRL_OFFSET		0x0100U
#define XPS_L2CC_AUX_CNTRL_OFFSET	0x0104U
#define XPS_L2CC_TAG_RAM_CNTRL_OFFSET	0x0108U
#define XPS_L2CC_DATA_RAM_CNTRL_OFFSET	0x010CU

#define XPS_L2CC_EVNT_CNTRL_OFFSET	0x0200U
#define XPS_L2CC_EVNT_CNT1_CTRL_OFFSET	0x0204U
#define XPS_L2CC_EVNT_CNT0_CTRL_OFFSET	0x0208U
#define XPS_L2CC_EVNT_CNT1_VAL_OFFSET	0x020CU
#define XPS_L2CC_EVNT_CNT0_VAL_OFFSET	0x0210U

#define XPS_L2CC_IER_OFFSET		0x0214U		/* Interrupt Mask */
#define XPS_L2CC_IPR_OFFSET		0x0218U		/* Masked interrupt status */
#define XPS_L2CC_ISR_OFFSET		0x021CU		/* Raw Interrupt Status */
#define XPS_L2CC_IAR_OFFSET		0x0220U		/* Interrupt Clear */

#define XPS_L2CC_CACHE_SYNC_OFFSET		0x0730U		/* Cache Sync */
#define XPS_L2CC_DUMMY_CACHE_SYNC_OFFSET	0x0740U		/* Dummy Register for Cache Sync */
#define XPS_L2CC_CACHE_INVLD_PA_OFFSET		0x0770U		/* Cache Invalid by PA */
#define XPS_L2CC_CACHE_INVLD_WAY_OFFSET		0x077CU		/* Cache Invalid by Way */
#define XPS_L2CC_CACHE_CLEAN_PA_OFFSET		0x07B0U		/* Cache Clean by PA */
#define XPS_L2CC_CACHE_CLEAN_INDX_OFFSET	0x07B8U		/* Cache Clean by Index */
#define XPS_L2CC_CACHE_CLEAN_WAY_OFFSET		0x07BCU		/* Cache Clean by Way */
#define XPS_L2CC_CACHE_INV_CLN_PA_OFFSET	0x07F0U		/* Cache Invalidate and Clean by PA */
#define XPS_L2CC_CACHE_INV_CLN_INDX_OFFSET	0x07F8U		/* Cache Invalidate and Clean by Index */
#define XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET	0x07FCU		/* Cache Invalidate and Clean by Way */

#define XPS_L2CC_CACHE_DLCKDWN_0_WAY_OFFSET	0x0900U		/* Cache Data Lockdown 0 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_0_WAY_OFFSET	0x0904U		/* Cache Instruction Lockdown 0 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_1_WAY_OFFSET	0x0908U		/* Cache Data Lockdown 1 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_1_WAY_OFFSET	0x090CU		/* Cache Instruction Lockdown 1 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_2_WAY_OFFSET	0x0910U		/* Cache Data Lockdown 2 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_2_WAY_OFFSET	0x0914U		/* Cache Instruction Lockdown 2 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_3_WAY_OFFSET	0x0918U		/* Cache Data Lockdown 3 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_3_WAY_OFFSET	0x091CU		/* Cache Instruction Lockdown 3 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_4_WAY_OFFSET	0x0920U		/* Cache Data Lockdown 4 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_4_WAY_OFFSET	0x0924U		/* Cache Instruction Lockdown 4 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_5_WAY_OFFSET	0x0928U		/* Cache Data Lockdown 5 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_5_WAY_OFFSET	0x092CU		/* Cache Instruction Lockdown 5 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_6_WAY_OFFSET	0x0930U		/* Cache Data Lockdown 6 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_6_WAY_OFFSET	0x0934U		/* Cache Instruction Lockdown 6 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_7_WAY_OFFSET	0x0938U		/* Cache Data Lockdown 7 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_7_WAY_OFFSET	0x093CU		/* Cache Instruction Lockdown 7 by Way */

#define XPS_L2CC_CACHE_LCKDWN_LINE_ENABLE_OFFSET 0x0950U		/* Cache Lockdown Line Enable */
#define XPS_L2CC_CACHE_UUNLOCK_ALL_WAY_OFFSET	0x0954U		/* Cache Unlock All Lines by Way */

#define XPS_L2CC_ADDR_FILTER_START_OFFSET	0x0C00U		/* Start of address filtering */
#define XPS_L2CC_ADDR_FILTER_END_OFFSET		0x0C04U		/* Start of address filtering */

#define XPS_L2CC_DEBUG_CTRL_OFFSET		0x0F40U		/* Debug Control Register */

/* XPS_L2CC_CNTRL_OFFSET bit masks */
#define XPS_L2CC_ENABLE_MASK		0x00000001U	/* enables the L2CC */

/* XPS_L2CC_AUX_CNTRL_OFFSET bit masks */
#define XPS_L2CC_AUX_EBRESPE_MASK	0x40000000U	/* Early BRESP Enable */
#define XPS_L2CC_AUX_IPFE_MASK		0x20000000U	/* Instruction Prefetch Enable */
#define XPS_L2CC_AUX_DPFE_MASK		0x10000000U	/* Data Prefetch Enable */
#define XPS_L2CC_AUX_NSIC_MASK		0x08000000U	/* Non-secure interrupt access control */
#define XPS_L2CC_AUX_NSLE_MASK		0x04000000U	/* Non-secure lockdown enable */
#define XPS_L2CC_AUX_CRP_MASK		0x02000000U	/* Cache replacement policy */
#define XPS_L2CC_AUX_FWE_MASK		0x01800000U	/* Force write allocate */
#define XPS_L2CC_AUX_SAOE_MASK		0x00400000U	/* Shared attribute override enable */
#define XPS_L2CC_AUX_PE_MASK		0x00200000U	/* Parity enable */
#define XPS_L2CC_AUX_EMBE_MASK		0x00100000U	/* Event monitor bus enable */
#define XPS_L2CC_AUX_WAY_SIZE_MASK	0x000E0000U	/* Way-size */
#define XPS_L2CC_AUX_ASSOC_MASK		0x00010000U	/* Associativity */
#define XPS_L2CC_AUX_SAIE_MASK		0x00002000U	/* Shared attribute invalidate enable */
#define XPS_L2CC_AUX_EXCL_CACHE_MASK	0x00001000U	/* Exclusive cache configuration */
#define XPS_L2CC_AUX_SBDLE_MASK		0x00000800U	/* Store buffer device limitation Enable */
#define XPS_L2CC_AUX_HPSODRE_MASK	0x00000400U	/* High Priority for SO and Dev Reads Enable */
#define XPS_L2CC_AUX_FLZE_MASK		0x00000001U	/* Full line of zero enable */

#define XPS_L2CC_AUX_REG_DEFAULT_MASK	0x72360000U	/* Enable all prefetching, */
                                                    /* Cache replacement policy, Parity enable, */
                                                    /* Event monitor bus enable and Way Size (64 KB) */
#define XPS_L2CC_AUX_REG_ZERO_MASK	0xFFF1FFFFU	/* */

#define XPS_L2CC_TAG_RAM_DEFAULT_MASK	0x00000111U	/* latency for TAG RAM */
#define XPS_L2CC_DATA_RAM_DEFAULT_MASK	0x00000121U	/* latency for DATA RAM */

/* Interrupt bit masks */
#define XPS_L2CC_IXR_DECERR_MASK	0x00000100U	/* DECERR from L3 */
#define XPS_L2CC_IXR_SLVERR_MASK	0x00000080U	/* SLVERR from L3 */
#define XPS_L2CC_IXR_ERRRD_MASK		0x00000040U	/* Error on L2 data RAM (Read) */
#define XPS_L2CC_IXR_ERRRT_MASK		0x00000020U	/* Error on L2 tag RAM (Read) */
#define XPS_L2CC_IXR_ERRWD_MASK		0x00000010U	/* Error on L2 data RAM (Write) */
#define XPS_L2CC_IXR_ERRWT_MASK		0x00000008U	/* Error on L2 tag RAM (Write) */
#define XPS_L2CC_IXR_PARRD_MASK		0x00000004U	/* Parity Error on L2 data RAM (Read) */
#define XPS_L2CC_IXR_PARRT_MASK		0x00000002U	/* Parity Error on L2 tag RAM (Read) */
#define XPS_L2CC_IXR_ECNTR_MASK		0x00000001U	/* Event Counter1/0 Overflow Increment */

/* Address filtering mask and enable bit */
#define XPS_L2CC_ADDR_FILTER_VALID_MASK	0xFFF00000U	/* Address filtering valid bits*/
#define XPS_L2CC_ADDR_FILTER_ENABLE_MASK 0x00000001U	/* Address filtering enable bit*/

/* Debug control bits */
#define XPS_L2CC_DEBUG_SPIDEN_MASK	0x00000004U	/* Debug SPIDEN bit */
#define XPS_L2CC_DEBUG_DWB_MASK		0x00000002U	/* Debug DWB bit, forces write through */
#define XPS_L2CC_DEBUG_DCL_MASK		0x00000002U	/* Debug DCL bit, disables cache line fill */

#ifdef __cplusplus
}
#endif

#endif /* protection macro */
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     aa_wvalid          ;
  wire                                                            aa_wready         ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                                    si_wready;
  
  reg  [7:0]                                                      debug_r_beat_cnt_i;
  reg  [7:0]                                                      debug_w_beat_cnt_i;
  reg  [7:0]                                                      debug_aw_trans_seq_i;
  reg  [7:0]                                                      debug_ar_trans_seq_i;

  reg aresetn_d = 1'b0; // Reset delay register
  always @(posedge ACLK) begin
    if (~ARESETN) begin
      aresetn_d <= 1'b0;
    end else begin
      aresetn_d <= ARESETN;
    end
  end
  wire reset;
  assign reset = ~aresetn_d;

  generate
    axi_crossbar_v2_1_addr_arbiter_sasd #
      (
       .C_FAMILY                (C_FAMILY),
       .C_NUM_S                 (C_NUM_SLAVE_SLOTS),
       .C_NUM_S_LOG             (P_NUM_SLAVE_SLOTS_LOG),
       .C_AMESG_WIDTH            (P_AMESG_WIDTH),
       .C_GRANT_ENC             (1),
       .C_ARB_PRIORITY          (C_S_AXI_ARB_PRIORITY)
       )
      addr_arbiter_inst
        (
         .ACLK                  (ACLK),
         .ARESET                (reset),
         // Vector of SI-side AW command request inputs
         .S_AWMESG                (si_awmesg),
         .S_ARMESG                (si_armesg),
         .S_AWVALID               (S_AXI_AWVALID),
         .S_AWREADY               (S_AXI_AWREADY),
         .S_ARVALID               (S_AXI_ARVALID),
         .S_ARREADY               (S_AXI_ARREADY),
         .M_GRANT_ENC           (aa_grant_enc),
         .M_GRANT_HOT           (aa_grant_hot),  // SI-slot 1-hot mask of granted command
         .M_GRANT_ANY             (aa_grant_any),
         .M_GRANT_RNW             (aa_grant_rnw),
         .M_AMESG                (aa_amesg),  // Either S_AWMESG or S_ARMESG, as indicated by M_AWVALID and M_ARVALID.
         .M_AWVALID               (aa_awvalid),
         .M_AWREADY               (aa_awready),
         .M_ARVALID               (aa_arvalid),
         .M_ARREADY               (aa_arready)
         );

    if (C_ADDR_DECODE) begin : gen_addr_decoder
      axi_crossbar_v2_1_addr_decoder #
        (
          .C_FAMILY          (C_FAMILY),
          .C_NUM_TARGETS     (C_NUM_MASTER_SLOTS),
          .C_NUM_TARGETS_LOG (P_NUM_MASTER_SLOTS_LOG),
          .C_NUM_RANGES      (C_NUM_ADDR_RANGES),
          .C_ADDR_WIDTH      (C_AXI_ADDR_WIDTH),
          .C_TARGET_ENC      (1),
          .C_TARGET_HOT      (1),
          .C_REGION_ENC      (1),
          .C_BASE_ADDR      (C_M_AXI_BASE_ADDR),
          .C_HIGH_ADDR      (C_M_AXI_HIGH_ADDR),
          .C_TARGET_QUAL     ({C_NUM_MASTER_SLOTS{1'b1}}),
          .C_RESOLUTION      (2)
        ) 
        addr_decoder_inst 
        (
          .ADDR             (mi_aaddr),        
          .TARGET_HOT       (target_mi_hot),  
          .TARGET_ENC       (target_mi_enc),  
          .MATCH            (match),       
          .REGION           (target_region)      
        );
    end else begin : gen_no_addr_decoder
      assign target_mi_hot = 1;
      assign match = 1'b1;
      assign target_region = 4'b0000;
    end  // gen_addr_decoder
    
    // AW-channel arbiter command transfer completes upon completion of both M-side AW-channel transfer and B channel completion.
    axi_crossbar_v2_1_splitter #  
      (
        .C_NUM_M                (3)
      )
      splitter_aw
      (
         .ACLK                  (ACLK),
         .ARESET                (reset),
         .S_VALID              (aa_awvalid),
         .S_READY              (aa_awready),
         .M_VALID              ({mi_awvalid_en, w_transfer_en, b_transfer_en}),
         .M_READY              ({mi_awready_mux, w_complete_mux, b_complete_mux})
      );
    
    // AR-channel arbiter command transfer completes upon completion of both M-side AR-channel transfer and R channel completion.
    axi_crossbar_v2_1_splitter #  
      (
        .C/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc. All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xil_assert.h
*
* This file contains assert related functions.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date   Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a hbm  07/14/09 First release
* </pre>
*
******************************************************************************/

#ifndef XIL_ASSERT_H	/* prevent circular inclusions */
#define XIL_ASSERT_H	/* by using protection macros */

#include "xil_types.h"

#ifdef __cplusplus
extern "C" {
#endif


/***************************** Include Files *********************************/


/************************** Constant Definitions *****************************/

#define XIL_ASSERT_NONE     0U
#define XIL_ASSERT_OCCURRED 1U
#define XNULL NULL

extern u32 Xil_AssertStatus;
extern void Xil_Assert(const char8 *File, s32 Line);
void XNullHandler(void *NullParameter);

/**
 * This data type defines a callback to be invoked when an
 * assert occurs. The callback is invoked only when asserts are enabled
 */
typedef void (*Xil_AssertCallback) (const char8 *File, s32 Line);

/***************** Macros (Inline Functions) Definitions *********************/

#ifndef NDEBUG

/*****************************************************************************/
/**
* This assert macro is to be used for functions that do not return anything
* (void). This in conjunction with the Xil_AssertWait boolean can be used to
* accomodate tests so that asserts which fail allow execution to continue.
*
* @param    Expression is the expression to evaluate. If it evaluates to
*           false, the assert occurs.
*
* @return   Returns void unless the Xil_AssertWait variable is true, in which
*           case no return is made and an infinite loop is entered.
*
* @note     None.
*
******************************************************************************/
#define Xil_AssertVoid(Expression)                \
{                                                  \
    if (Expression) {                              \
        Xil_AssertStatus = XIL_ASSERT_NONE;       \
    } else {                                       \
        Xil_Assert(__FILE__, __LINE__);            \
        Xil_AssertStatus = XIL_ASSERT_OCCURRED;   \
        return;                                    \
    }                                              \
}

/*****************************************************************************/
/**
* This assert macro is to be used for functions that do return a value. This in
* conjunction with the Xil_AssertWait boolean can be used to accomodate tests
* so that asserts which fail allow execution to continue.
*
* @param    Expression is the expression to evaluate. If it evaluates to false,
*           the assert occurs.
*
* @return   Returns 0 unless the Xil_AssertWait variable is true, in which
* 	    case no return is made and an infinite loop is entered.
*
* @note     None.
*
******************************************************************************/
#define Xil_AssertNonvoid(Expression)             \
{                                                  \
    if (Expression) {                              \
        Xil_AssertStatus = XIL_ASSERT_NONE;       \
    } else {                                       \
        Xil_Assert(__FILE__, __LINE__);            \
        Xil_AssertStatus = XIL_ASSERT_OCCURRED;   \
        return 0;                                  \
    }                                              \
}

/*****************************************************************************/
/**
* Always assert. This assert macro is to be used for functions that do not
* return anything (void). Use for instances where an assert should always
* occur.
*
* @return Returns void unless the Xil_AssertWait variable is true, in which
*	  case no return is made and an infinite loop is entered.
*
* @note   None.
*
******************************************************************************/
#define Xil_AssertVoidAlways()                   \
{                                                  \
   Xil_Assert(__FILE__, __LINE__);                 \
   Xil_AssertStatus = XIL_ASSERT_OCCURRED;        \
   return;                                         \
}

/*****************************************************************************/
/**
* Always assert. This assert macro is to be used for functions that do return
* a value. Use for instances where an assert should always occur.
*
* @return Returns void unless the Xil_AssertWait variable is true, in which
*	  case no return is made and an infinite loop is entered.
*
* @note   None.
*
******************************************************************************/
#define Xil_AssertNonvoidAlways()                \
{                                                  \
   Xil_Assert(__FILE__, __LINE__);                 \
   Xil_AssertStatus = XIL_ASSERT_OCCURRED;        \
   return 0;                                       \
}


#else

#define Xil_AssertVoid(Expression)
#define Xil_AssertVoidAlways()
#define Xil_AssertNonvoid(Expression)
#define Xil_AssertNonvoidAlways()

#endif

/************************** Function Prototypes ******************************/

void Xil_AssertSetCallback(Xil_AssertCallback Routine);

#ifdef __cplusplus
}
#endif

#endif	/* end of protection macro */
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ots
    assign M_AXI_AWID        = {C_NUM_MASTER_SLOTS{mi_aid}};
    assign M_AXI_AWADDR      = {C_NUM_MASTER_SLOTS{mi_aaddr}};
    assign M_AXI_AWLEN       = {C_NUM_MASTER_SLOTS{mi_alen }};
    assign M_AXI_AWSIZE      = {C_NUM_MASTER_SLOTS{mi_asize}};
    assign M_AXI_AWLOCK      = {C_NUM_MASTER_SLOTS{mi_alock}};
    assign M_AXI_AWPROT      = {C_NUM_MASTER_SLOTS{mi_aprot}};
    assign M_AXI_AWREGION    = {C_NUM_MASTER_SLOTS{mi_aregion}};
    assign M_AXI_AWBURST     = {C_NUM_MASTER_SLOTS{mi_aburst}};
    assign M_AXI_AWCACHE     = {C_NUM_MASTER_SLOTS{mi_acache}};
    assign M_AXI_AWQOS       = {C_NUM_MASTER_SLOTS{mi_aqos  }};
    assign M_AXI_AWUSER      = {C_NUM_MASTER_SLOTS{mi_auser[0+:C_AXI_AWUSER_WIDTH] }};
    
    // Broadcast AR transfer payload to all MI-slots
    assign M_AXI_ARID        = {C_NUM_MASTER_SLOTS{mi_aid}};
    assign M_AXI_ARADDR      = {C_NUM_MASTER_SLOTS{mi_aaddr}};                        
    assign M_AXI_ARLEN       = {C_NUM_MASTER_SLOTS{mi_alen }};                        
    assign M_AXI_ARSIZE      = {C_NUM_MASTER_SLOTS{mi_asize}};                        
    assign M_AXI_ARLOCK      = {C_NUM_MASTER_SLOTS{mi_alock}};                        
    assign M_AXI_ARPROT      = {C_NUM_MASTER_SLOTS{mi_aprot}};                        
    assign M_AXI_ARREGION    = {C_NUM_MASTER_SLOTS{mi_aregion}};                          
    assign M_AXI_ARBURST     = {C_NUM_MASTER_SLOTS{mi_aburst}};                       
    assign M_AXI_ARCACHE     = {C_NUM_MASTER_SLOTS{mi_acache}};                       
    assign M_AXI_ARQOS       = {C_NUM_MASTER_SLOTS{mi_aqos  }};                       
    assign M_AXI_ARUSER      = {C_NUM_MASTER_SLOTS{mi_auser[0+:C_AXI_ARUSER_WIDTH] }};
    
    // W-channel MI handshakes
    assign M_AXI_WVALID = mi_wvalid[0+:C_NUM_MASTER_SLOTS];
    assign mi_wready[0+:C_NUM_MASTER_SLOTS] = M_AXI_WREADY;
    // Broadcast W transfer payload to all MI-slots
    assign M_AXI_WLAST = {C_NUM_MASTER_SLOTS{mi_wlast}};
    assign M_AXI_WUSER = {C_NUM_MASTER_SLOTS{mi_wuser}};
    assign M_AXI_WDATA = {C_NUM_MASTER_SLOTS{mi_wdata}};
    assign M_AXI_WSTRB = {C_NUM_MASTER_SLOTS{mi_wstrb}};
    assign M_AXI_WID =   {C_NUM_MASTER_SLOTS{mi_wid}};
    
    // Broadcast R transfer payload to all SI-slots
    assign S_AXI_RLAST = {C_NUM_SLAVE_SLOTS{si_rlast}};
    assign S_AXI_RRESP = {C_NUM_SLAVE_SLOTS{si_rresp}};
    assign S_AXI_RUSER = {C_NUM_SLAVE_SLOTS{si_ruser}};
    assign S_AXI_RDATA = {C_NUM_SLAVE_SLOTS{si_rdata}};
    assign S_AXI_RID =   {C_NUM_SLAVE_SLOTS{mi_aid}};
    
    // Broadcast B transfer payload to all SI-slots
    assign S_AXI_BRESP = {C_NUM_SLAVE_SLOTS{si_bresp}};
    assign S_AXI_BUSER = {C_NUM_SLAVE_SLOTS{si_buser}};
    assign S_AXI_BID =   {C_NUM_SLAVE_SLOTS{mi_aid}};
    
    if (C_NUM_SLAVE_SLOTS>1) begin : gen_wmux
      // SI WVALID mux.
      generic_baseblocks_v2_1_mux_enc # 
        (
         .C_FAMILY      ("rtl"),
         .C_RATIO       (C_NUM_SLAVE_SLOTS),
         .C_SEL_WIDTH   (P_NUM_SLAVE_SLOTS_LOG),
         .C_DATA_WIDTH  (1)
        ) si_w_valid_mux_inst 
        (
         .S   (aa_grant_enc),
         .A   (S_AXI_WVALID),
         .O   (aa_wvalid),
         .OE  (w_transfer_en)
        ); 
      
      // SI W-channel payload mux
      generic_baseblocks_v2_1_mux_enc # 
        (
         .C_FAMILY      ("rtl"),
         .C_RATIO       (C_NUM_SLAVE_SLOTS),
         .C_SEL_WIDTH   (P_NUM_SLAVE_SLOTS_LOG),
         .C_DATA_WIDTH  (P_WMESG_WIDTH)
        ) si_w_payload_mux_inst 
        (
         .S   (aa_grant_enc),
         .A   (si_wmesg),
         .O   (mi_wmesg),
         .OE  (1'b1)
        ); 
        
      for (gen_si_slot=0; gen_si_slot<C_NUM_SLAVE_SLOTS; gen_si_slot=gen_si_slot+1) begin : gen_wmesg
        assign si_wmesg[gen_si_slot*P_WMESG_WIDTH+:P_WMESG_WIDTH] = {  // Concatenate from MSB to LSB
          ((C_AXI_PROTOCOL == P_AXI3) ? f_extend_ID(S_AXI_WID[gen_si_slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH], gen_si_slot) : 1'b0),
          S_AXI_WUSER[gen_si_slot*C_AXI_WUSER_WIDTH+:C_AXI_WUSER_WIDTH],
          S_AXI_WSTRB[gen_si_slot*C_AXI_DATA_WIDTH/8+:C_AXI_DATA_WIDTH/8],
          S_AXI_WDATA[gen_si_slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH],
          S_AXI_WLAST[gen_si_slot*1+:1]
        };
      end  // gen_wmesg
      
      assign mi_wlast = mi_wmesg[0];
      assign mi_wdata = mi_wmesg[1 +: C_AXI_DATA_WIDTH];
      assign mi_wstrb = mi_wmesg[1+C_AXI_DATA_WIDTH +: C_AXI_DATA_WIDTH/8];
      assign mi_wuser = mi_wmesg[1+C_AXI_DATA_WIDTH+C_AXI_DATA_WIDTH/8 +: C_AXI_WUSER_WIDTH];
      assign mi_wid =   mi_wmesg[1+C_AXI_DATA_WIDTH+C_AXI_DATA_WIDTH/8+C_AXI_WUSER_WIDTH +: P_AXI_WID_WIDTH];
    end else begin : gen_no_wmux
      assign aa_wvalid = w_transfer_en & S_AXI_WVALID;
      assign mi_wlast  = S_AXI_WLAST;
      assign mi_wdata  = S_AXI_WDATA;
      assign mi_wstrb  = S_AXI_WSTRB;
      assign mi_wuser  = S_AXI_WUSER;
      assign mi_wid =    S_AXI_WID;
    end  // gen_wmux
    
    // Receive RVALID from targeted MI.
    generic_baseblocks_v2_1_mux_enc # 
      (
       .C_FAMILY      ("rtl"),
       .C_RATIO       (P_NUM_MASTER_SLOTS_DE),
       .C_SEL_WIDTH   (P_NUM_MASTER_SLOTS_DE_LOG),
       .C_DATA_WIDTH  (1)
      ) mi_rvalid_mux_inst 
      (
       .S   (m_atarget_enc),
       .A   (mi_rvalid),
       .O   (aa_rvalid),
       .OE  (r_transfer_en)
      ); 
      
    // MI R-channel payload mux
    generic_baseblocks_v2_1_mux_enc # 
      (
       .C_FAMILY      ("rtl"),
       .C_RATIO       (P_NUM_MASTER_SLOTS_DE),
       .C_SEL_WIDTH   (P_NUM_MASTER_SLOTS_DE_LOG),
       .C_DATA_WIDTH  (P_RMESG_WIDTH)
      ) mi_rmesg_mux_inst 
      (
       .S   (m_atarget_enc),
       .A   (mi_rmesg),
       .O   (aa_rmesg),
       .OE  (1'b1)
      ); 
      
    axi_register_slice_v2_1_axic_register_slice #
      (
       .C_FAMILY (C_FAMILY),
       .C_DATA_WIDTH (P_RMESG_WIDTH),
       .C_REG_CONFIG (P_R_REG_CONFIG)
       )
      reg_slice_r
      (
       // System Signals
       .ACLK(ACLK),
       .ARESET(reset),

       // Slave side
       .S_PAYLOAD_DATA(aa_rmesg),
       .S_VALID(aa_rvalid),
       .S_READY(aa_rready),

       // Master side
       .M_PAYLOAD_DATA(sr_rmesg),
       .M_VALID(sr_rvalid),
       .M_READY(sr_rready)
       );

    assign mi_rvalid[0+:C_NUM_MASTER_SLOTS] = M_AXI_RVALID; 
    assign mi_rlast[0+:C_NUM_MASTER_SLOTS] = M_AXI_RLAST; 
    assign mi_rresp[0+:C_NUM_MASTER_SLOTS*2] = M_AXI_RRESP;
    assign mi_ruser[0+:C_NUM_MASTER_SLOTS*C_AXI_RUSER_WIDTH] = M_AXI_RUSER;
    assign mi_rdata[0+:C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH] = M_AXI_RDATA;
    assign M_AXI_RREADY = mi_rready[0+:C_NUM_MASTER_SLOTS];
    
    for (gen_mi_slot=0; gen_mi_slot<P_NUM_MASTER_SLOTS_DE; gen_mi_slot=gen_mi_slot+1) begin : gen_rmesg
      assign mi_rmesg[gen_mi_slot*P_RMESG_WIDTH+:P_RMESG_WIDTH] = {  // Concatenate from MSB to LSB
        mi_ruser[gen_mi_slot*C_AXI_RUSER_WIDTH+:C_AXI_RUSER_WIDTH],
        mi_rdata[gen_mi_slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH],
        mi_rresp[gen_mi_slot*2+:2],
        mi_rlast[gen_mi_slot*1+:1]
      };
    end  // gen_rmesg
    
    assign si_rlast = sr_rmesg[0];
    assign si_rresp = sr_rmesg[1 +: 2];
    assign si_rdata = sr_rmesg[1+2 +: C_AXI_DATA_WIDTH];
    assign si_ruser = sr_rmesg[1+2+C_AXI_DATA_WIDTH +: C_AXI_RUSER_WIDTH];
      
    // Receive BVALID from targeted MI.
    generic_baseblocks_v2_1_mux_enc # 
      (
       .C_FAMILY      ("rtl"),
       .C_RATIO       (P_NUM_MASTER_SLOTS_DE),
       .C_SEL_WIDTH   (P_NUM_MASTER_SLOTS_DE_LOG),
       .C_DATA_WIDTH  (1)
      ) mi_bvalid_mux_inst 
      (
       .S   (m_atarget_enc),
       .A   (mi_bvalid),
       .O   (aa_bvalid),
       .OE  (b_transfer_en)
      ); 
      
    // MI B-channel payload mux
    generic_baseblocks_v2_1_mux_enc # 
      (
       .C_FAMILY      ("rtl"),
       .C_RATIO       (P_NUM_MASTER_SLOTS_DE),
       .C_SEL_WIDTH   (P_NUM_MASTER_SLOTS_DE_LOG),
       .C_DATA_WIDTH  (P_BMESG_WIDTH)
      ) mi_bmesg_mux_inst 
      (
       .S   (m_atarget_enc),
       .A   (mi_bmesg),
       .O   (si_bmesg),
       .OE  (1'b1)
      ); 
      
    assign mi_bvalid[0+:C_NUM_MASTER_SLOTS] = M_AXI_BVALID; 
    assign mi_bresp[0+:C_NUM_MASTER_SLOTS*2] = M_AXI_BRESP;
    assign mi_buser[0+:C_NUM_MASTER_SLOTS*C_AXI_BUSER_WIDTH] = M_AXI_BUSER;
    assign M_AXI_BREADY = mi_bready[0+:C_NUM_MASTER_SLOTS];
    
    for (gen_mi_slot=0; gen_mi_slot<P_NUM_MASTER_SLOTS_DE; gen_mi_slot=gen_mi_slot+1) begin : gen_bmesg
      assign mi_bmesg[gen_mi_slot*P_BMESG_WIDTH+:P_BMESG_WIDTH] = {  // Concatenate from MSB to LSB
        mi_buser[gen_mi_slot*C_AXI_BUSER_WIDTH+:C_AXI_BUSER_WIDTH],
        mi_bresp[gen_mi_slot*2+:2]
      };
    end  // gen_bmesg
    
    assign si_bresp = si_bmesg[0 +: 2];
    assign si_buser = si_bmesg[2 +: C_AXI_BUSER_WIDTH];
    
    if (C_DEBUG) begin : gen_debug_trans_seq
      // DEBUG WRITE TRANSACTION SEQUENCE COUNTER
      always @(posedge ACLK) begin
        if (reset) begin
          debug_aw_trans_seq_i <= 1;
        end else begin
          if (aa_awvalid && aa_awready) begin
            debug_aw_trans_seq_i <= debug_aw_trans_seq_i + 1;
          end
        end
      end
  
      // DEBUG READ TRANSACTION SEQUENCE COUNTER
      always @(posedge ACLK) begin
        if (reset) begin
          debug_ar_trans_seq_i <= 1;
        end else begin
          if (aa_arvalid && aa_arready) begin
            debug_ar_trans_seq_i <= debug_ar_trans_seq_i + 1;
          end
        end
      end
      
      // DEBUG WRITE BEAT COUNTER 
      always @(posedge ACLK) begin
        if (reset) begin
          debug_w_beat_cnt_i <= 0;
        end else if (aa_wready & aa_wvalid) begin
          if (mi_wlast) begin
            debug_w_beat_cnt_i <= 0;
          end else begin
            debug_w_beat_cnt_i <= debug_w_beat_cnt_i + 1;
          end
        end
      end  // Clocked process
    
      // DEBUG READ BEAT COUNTER 
      always @(posedge ACLK) begin
        if (reset) begin
          debug_r_beat_cnt_i <= 0;
        end else if (sr_rready & sr_rvalid) begin
          if (si_rlast) begin
            debug_r_beat_cnt_i <= 0;
          end else begin
            debug_r_beat_cnt_i <= debug_r_beat_cnt_i + 1;
          end
        end
      end  // Clocked process
    
    end  // gen_debug_trans_seq

    if (C_RANGE_CHECK) begin : gen_decerr
      // Highest MI-slot (index C_NUM_MASTER_SLOTS) is the error handler
      axi_crossbar_v2_1_decerr_slave #
        (
         .C_AXI_ID_WIDTH                 (1),
         .C_AXI_DATA_WIDTH               (C_AXI_DATA_WIDTH),
         .C_AXI_RUSER_WIDTH                (C_AXI_RUSER_WIDTH),
         .C_AXI_BUSER_WIDTH                (C_AXI_BUSER_WIDTH),
         .C_AXI_PROTOCOL                 (C_AXI_PROTOCOL),
         .C_RESP                         (P_DECERR) 
        )
        decerr_slave_inst
          (
           .S_AXI_ACLK (ACLK),
           .S_AXI_ARESET (reset),
           .S_AXI_AWID (1'b0),
           .S_AXI_AWVALID (mi_awvalid[C_NUM_MASTER_SLOTS]),
           .S_AXI_AWREADY (mi_awready[C_NUM_MASTER_SLOTS]),
           .S_AXI_WLAST (mi_wlast),
           .S_AXI_WVALID (mi_wvalid[C_NUM_MASTER_SLOTS]),
           .S_AXI_WREADY (mi_wready[C_NUM_MASTER_SLOTS]),
           .S_AXI_BID (),
           .S_AXI_BRESP (mi_bresp[C_NUM_MASTER_SLOTS*2+:2]),
           .S_AXI_BUSER (mi_buser[C_NUM_MASTER_SLOTS*C_AXI_BUSER_WIDTH+:C_AXI_BUSER_WIDTH]),
           .S_AXI_BVALID (mi_bvalid[C_NUM_MASTER_SLOTS]),
           .S_AXI_BREADY (mi_bready[C_NUM_MASTER_SLOTS]),
           .S_AXI_ARID (1'b0),
           .S_AXI_ARLEN (mi_alen),
           .S_AXI_ARVALID (mi_arvalid[C_NUM_MASTER_SLOTS]),
           .S_AXI_ARREADY (mi_arready[C_NUM_MASTER_SLOTS]),
           .S_AXI_RID (),
           .S_AXI_RDATA (mi_rdata[C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]),
           .S_AXI_RRESP (mi_rresp[C_NUM_MASTER_SLOTS*2+:2]),
           .S_AXI_RUSER (mi_ruser[C_NUM_MASTER_SLOTS*C_AXI_RUSER_WIDTH+:C_AXI_RUSER_WIDTH]),
           .S_AXI_RLAST (mi_rlast[C_NUM_MASTER_SLOTS]),
           .S_AXI_RVALID (mi_rvalid[C_NUM_MASTER_SLOTS]),
           .S_AXI_RREADY (mi_rready[C_NUM_MASTER_SLOTS])
         );
    end  // gen_decerr

  endgenerate

endmodule

`default_nettype wire
