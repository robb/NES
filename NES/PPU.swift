import Foundation

internal final class PPU {
    /// The PPU Control register.
    var PPUCTRL: UInt8 = 0

    /// The PPU Mask register.
    var PPUMASK: UInt8 = 0

    /// The PPU Status register.
    ///
    /// Setting the lower five bit has no effect.
    var PPUSTATUS: UInt8 = 0

    /// The OAM Address Port register.
    var OAMADDR: UInt8 = 0

    /// The OAM Data Port register.
    ///
    /// This property proxies the PPU's OAM at the address held by OAMADDR.
    var OAMDATA: UInt8 {
        get {
            return OAM[Int(OAMADDR)]
        }
        set {
            OAM[Int(OAMADDR)] = newValue
        }
    }

    /// The PPU scrolling position register.
    var PPUSCROLL: UInt8 = 0

    /// Holds the last value written to any of the above registers.
    ///
    /// Setting this will also affect the five lowest bits of PPUSTATUS.
    var register: UInt8 = 0 {
        didSet {
            PPUSTATUS = (PPUSTATUS & 0xE0) | (register & 0x1F)
        }
    }

    var temporaryVRAMAddress: Address = 0

    var horizontalScrollPosition: UInt8 = 0

    /// Toggled by writing to PPUSCROLL or PPUADDR, cleared by reading
    /// PPUSTATUS.
    var secondWrite: Bool = false

    /// The console this CPU is owned by.
    unowned let console: Console

    /// The CPU.
    var CPU: IO! {
        return console.CPU
    }

    /// The mapper the PPU reads from.
    var mapper: IO! {
        return console.mapper
    }

    /// The VRAM the PPU reads from.
    var VRAM: Array<UInt8>

    /// The Object Attribute Memory.
    var OAM: Array<UInt8> = Array(count: 0x0100, repeatedValue: 0x00)

    init(console: Console, VRAM: Array<UInt8> = Array(count: 0x800, repeatedValue: 0x00)) {
        self.console = console
        self.VRAM = VRAM
    }

    /// Must be called after the CPU has read PPUSTATUS.
    func didReadPPUSTATUS() {
        VBlankStarted = false
        secondWrite = false
    }

    /// Must be called after the CPU has written OAMDATA.
    func didWriteOAMDATA() {
        OAMADDR = OAMADDR &+ 1
    }

    /// Must be called after the CPU has written PPUSCROLL.
    func didWritePPUSCROLL() {
        if !secondWrite {
            temporaryVRAMAddress = (temporaryVRAMAddress & 0xFFE0) | (UInt16(PPUSCROLL) >> 3)
            horizontalScrollPosition = PPUSCROLL & 0x07
        } else {
            temporaryVRAMAddress = (temporaryVRAMAddress & 0x8FFF) | UInt16(PPUSCROLL & 0x07) << 12
            temporaryVRAMAddress = (temporaryVRAMAddress & 0xFC1F) | UInt16(PPUSCROLL & 0xF8) << 2
        }

        secondWrite = !secondWrite
    }
}