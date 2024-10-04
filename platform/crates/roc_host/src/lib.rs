#![allow(non_snake_case)]
#![allow(improper_ctypes)]
use core::alloc::Layout;
use core::ffi::c_void;
use core::mem::MaybeUninit;
//use roc_app::SomeType;
//use crossterm;
use roc_std::{RocResult, RocStr};
//use std::io::ErrorKind;
use std::io::Write;
use std::time::Duration;

extern "C" {
    #[link_name = "roc__mainForHost_1_exposed_generic"]
    //pub fn roc_main(output: *mut u8, roc_args: *mut u32);
    pub fn roc_main(output: *mut u8);

    #[link_name = "roc__mainForHost_1_exposed_size"]
    pub fn roc_main_size() -> i64;

    #[link_name = "roc__mainForHost_0_caller"]
    fn call_Fx(flags: *const u8, closure_data: *const u8, output: *mut RocResult<(), ()>);
}

#[no_mangle]
pub unsafe extern "C" fn roc_alloc(size: usize, _alignment: u32) -> *mut c_void {
    libc::malloc(size)
}

#[no_mangle]
pub unsafe extern "C" fn roc_realloc(
    c_ptr: *mut c_void,
    new_size: usize,
    _old_size: usize,
    _alignment: u32,
) -> *mut c_void {
    libc::realloc(c_ptr, new_size)
}

#[no_mangle]
pub unsafe extern "C" fn roc_dealloc(c_ptr: *mut c_void, _alignment: u32) {
    libc::free(c_ptr)
}

fn reset_terminal() {
    _ = crossterm::terminal::disable_raw_mode();
    _ = crossterm::execute!(
        std::io::stdout(),
        crossterm::style::SetForegroundColor(crossterm::style::Color::Reset),
        crossterm::style::SetBackgroundColor(crossterm::style::Color::Reset),
        crossterm::cursor::Show
    );
}

#[no_mangle]
pub unsafe extern "C" fn roc_panic(msg: &RocStr, tag_id: u32) {
    reset_terminal();
    match tag_id {
        0 => {
            eprintln!("Roc crashed with:\n\n\t{}\n", msg.as_str());

            print_backtrace();
            std::process::exit(1);
        }
        1 => {
            eprintln!("The program crashed with:\n\n\t{}\n", msg.as_str());

            print_backtrace();
            std::process::exit(1);
        }
        _ => todo!(),
    }
}

#[no_mangle]
pub unsafe extern "C" fn roc_dbg(loc: &RocStr, msg: &RocStr, src: &RocStr) {
    eprintln!("[{}] {} = {}", loc, src, msg);
}

#[cfg(unix)]
#[no_mangle]
pub unsafe extern "C" fn roc_getppid() -> libc::pid_t {
    libc::getppid()
}

#[cfg(unix)]
#[no_mangle]
pub unsafe extern "C" fn roc_mmap(
    addr: *mut libc::c_void,
    len: libc::size_t,
    prot: libc::c_int,
    flags: libc::c_int,
    fd: libc::c_int,
    offset: libc::off_t,
) -> *mut libc::c_void {
    libc::mmap(addr, len, prot, flags, fd, offset)
}

#[cfg(unix)]
#[no_mangle]
pub unsafe extern "C" fn roc_shm_open(
    name: *const libc::c_char,
    oflag: libc::c_int,
    mode: libc::mode_t,
) -> libc::c_int {
    libc::shm_open(name, oflag, mode as libc::c_uint)
}

fn print_backtrace() {
    eprintln!("Here is the call stack that led to the crash:\n");

    let mut entries = Vec::new();

    #[derive(Default)]
    struct Entry {
        pub fn_name: String,
        pub filename: Option<String>,
        pub line: Option<u32>,
        pub col: Option<u32>,
    }

    backtrace::trace(|frame| {
        backtrace::resolve_frame(frame, |symbol| {
            if let Some(fn_name) = symbol.name() {
                let fn_name = fn_name.to_string();

                if should_show_in_backtrace(&fn_name) {
                    let mut entry = Entry {
                        fn_name: format_fn_name(&fn_name),
                        ..Default::default()
                    };

                    if let Some(path) = symbol.filename() {
                        entry.filename = Some(path.to_string_lossy().into_owned());
                    };

                    entry.line = symbol.lineno();
                    entry.col = symbol.colno();

                    entries.push(entry);
                }
            } else {
                entries.push(Entry {
                    fn_name: "???".to_string(),
                    ..Default::default()
                });
            }
        });

        true // keep going to the next frame
    });

    for entry in entries {
        eprintln!("\t{}", entry.fn_name);

        if let Some(filename) = entry.filename {
            eprintln!("\t\t{filename}");
        }
    }

    eprintln!("\nOptimizations can make this list inaccurate! If it looks wrong, try running without `--optimize` and with `--linker=legacy`\n");
}

fn should_show_in_backtrace(fn_name: &str) -> bool {
    let is_from_rust = fn_name.contains("::");
    let is_host_fn = fn_name.starts_with("roc_panic")
        || fn_name.starts_with("_roc__")
        || fn_name.starts_with("rust_main")
        || fn_name == "_main";

    !is_from_rust && !is_host_fn
}

fn format_fn_name(fn_name: &str) -> String {
    // e.g. convert "_Num_sub_a0c29024d3ec6e3a16e414af99885fbb44fa6182331a70ab4ca0886f93bad5"
    // to ["Num", "sub", "a0c29024d3ec6e3a16e414af99885fbb44fa6182331a70ab4ca0886f93bad5"]
    let mut pieces_iter = fn_name.split('_');

    if let (_, Some(module_name), Some(name)) =
        (pieces_iter.next(), pieces_iter.next(), pieces_iter.next())
    {
        display_roc_fn(module_name, name)
    } else {
        "???".to_string()
    }
}

fn display_roc_fn(module_name: &str, fn_name: &str) -> String {
    let module_name = if module_name == "#UserApp" {
        "app"
    } else {
        module_name
    };

    let fn_name = if fn_name.parse::<u64>().is_ok() {
        "(anonymous function)"
    } else {
        fn_name
    };

    format!("\u{001B}[36m{module_name}\u{001B}[39m.{fn_name}")
}

/// # Safety
///
/// This function should be provided a valid dst pointer.
#[no_mangle]
pub unsafe extern "C" fn roc_memset(dst: *mut c_void, c: i32, n: usize) -> *mut c_void {
    libc::memset(dst, c, n)
}

// Protect our functions from the vicious GC.
// This is specifically a problem with static compilation and musl.
// TODO: remove all of this when we switch to effect interpreter.
pub fn init() {
    let funcs: &[*const extern "C" fn()] = &[
        roc_alloc as _,
        roc_realloc as _,
        roc_dealloc as _,
        roc_panic as _,
        roc_dbg as _,
        roc_memset as _,
    ];
    #[allow(forgetting_references)]
    std::mem::forget(std::hint::black_box(funcs));
    if cfg!(unix) {
        let unix_funcs: &[*const extern "C" fn()] =
            &[roc_getppid as _, roc_mmap as _, roc_shm_open as _];
        #[allow(forgetting_references)]
        std::mem::forget(std::hint::black_box(unix_funcs));
    }
}

#[no_mangle]
pub extern "C" fn rust_main() -> i32 {
    init();
    let size = unsafe { roc_main_size() } as usize;
    let layout = Layout::array::<u8>(size).unwrap();

    unsafe {
        println!("size: {}", size); // size is 0?

        let buffer = if size > 0 {
            std::alloc::alloc(layout)
        } else {
            std::ptr::null()
        } as *mut u8;

        // Hardcoded random seed until I figue out this segfault
        //let mut roc_args: u32 = 500;

        //roc_main(buffer, &mut roc_args);
        roc_main(buffer);

        let out = call_the_closure(buffer);

        if size > 0 {
            std::alloc::dealloc(buffer, layout);
        }

        reset_terminal();

        out
    }
}

/// # Safety
///
/// This function should be passed a pointer to a closure data buffer.
pub unsafe fn call_the_closure(closure_data_ptr: *const u8) -> i32 {
    let mut out: RocResult<(), ()> = RocResult::ok(());

    call_Fx(
        // This flags pointer will never get dereferenced
        MaybeUninit::uninit().as_ptr(),
        closure_data_ptr,
        &mut out,
    );

    // match out.into() {
    //     Ok(()) => 0,
    //     Err(exit_code) => exit_code,
    // }
    0
}

// -------------------------------- Stdout --------------------------------

// fn handleStdoutErr(io_err: std::io::Error) -> RocStr {
//     match io_err.kind() {
//         ErrorKind::BrokenPipe => "ErrorKind::BrokenPipe".into(),
//         ErrorKind::WouldBlock => "ErrorKind::WouldBlock".into(),
//         ErrorKind::WriteZero => "ErrorKind::WriteZero".into(),
//         ErrorKind::Unsupported => "ErrorKind::Unsupported".into(),
//         ErrorKind::Interrupted => "ErrorKind::Interrupted".into(),
//         ErrorKind::OutOfMemory => "ErrorKind::OutOfMemory".into(),
//         _ => format!("{:?}", io_err).as_str().into(),
//     }
// }
fn handleStdoutErr(_: std::io::Error) -> () {
    ()
}

#[no_mangle]
pub extern "C" fn roc_fx_stdoutLine(text: &RocStr) -> RocResult<(), ()> {
    let stdout = std::io::stdout();

    let mut handle = stdout.lock();

    handle
        .write_all(text.as_bytes())
        .and_then(|()| handle.write_all("\n".as_bytes()))
        .and_then(|()| handle.flush())
        .map_err(handleStdoutErr)
        .into()
}

#[no_mangle]
pub extern "C" fn roc_fx_stdoutPut(text: &RocStr) -> RocResult<(), ()> {
    let stdout = std::io::stdout();

    let mut handle = stdout.lock();

    handle
        .write_all(text.as_bytes())
        .and_then(|()| handle.flush())
        .map_err(handleStdoutErr)
        .into()
}

// -------------------------------- Terminal --------------------------------

#[no_mangle]
pub extern "C" fn roc_fx_terminalSetRawMode(raw: bool) -> RocResult<(), ()> {
    if raw {
        crossterm::terminal::enable_raw_mode().expect("failed to enable raw mode");
    } else {
        crossterm::terminal::disable_raw_mode().expect("failed to disable raw mode");
    }
    RocResult::ok(())
}

#[no_mangle]
pub extern "C" fn roc_fx_terminalClear() -> RocResult<(), ()> {
    _ = crossterm::execute!(
        std::io::stdout(),
        crossterm::terminal::Clear(crossterm::terminal::ClearType::All)
    );
    return RocResult::ok(());
}

#[no_mangle]
pub extern "C" fn roc_fx_terminalSetCursorVisible(visible: bool) -> RocResult<(), ()> {
    if visible {
        _ = crossterm::execute!(std::io::stdout(), crossterm::cursor::Show);
    } else {
        _ = crossterm::execute!(std::io::stdout(), crossterm::cursor::Hide);
    }
    RocResult::ok(())
}

#[no_mangle]
pub extern "C" fn roc_fx_terminalGoto(x: u16, y: u16) -> RocResult<(), ()> {
    _ = crossterm::execute!(std::io::stdout(), crossterm::cursor::MoveTo(x, y));
    RocResult::ok(())
}

#[no_mangle]
pub extern "C" fn roc_fx_terminalGetNextKey() -> RocResult<RocStr, ()> {
    let str = match crossterm::event::poll(Duration::from_millis(1)) {
        Ok(true) => match crossterm::event::read() {
            Ok(crossterm::event::Event::Key(key)) => {
                let result = format!("{:?}", key);
                result
            }
            _ => String::from(""),
        },
        _ => String::from(""),
    };

    RocResult::ok(RocStr::from(str.as_str()))
}

#[no_mangle]
pub extern "C" fn roc_fx_terminalSetForecolor(r: u8, g: u8, b: u8) -> RocResult<(), ()> {
    _ = crossterm::execute!(
        std::io::stdout(),
        crossterm::style::SetForegroundColor(crossterm::style::Color::Rgb { r: r, g: g, b: b })
    );
    RocResult::ok(())
}

#[no_mangle]
pub extern "C" fn roc_fx_terminalResetForecolor() -> RocResult<(), ()> {
    _ = crossterm::execute!(
        std::io::stdout(),
        crossterm::style::SetForegroundColor(crossterm::style::Color::Reset)
    );
    RocResult::ok(())
}

#[no_mangle]
pub extern "C" fn roc_fx_terminalSetBackcolor(r: u8, g: u8, b: u8) -> RocResult<(), ()> {
    _ = crossterm::execute!(
        std::io::stdout(),
        crossterm::style::SetBackgroundColor(crossterm::style::Color::Rgb { r: r, g: g, b: b })
    );
    RocResult::ok(())
}

#[no_mangle]
pub extern "C" fn roc_fx_terminalResetBackcolor() -> RocResult<(), ()> {
    _ = crossterm::execute!(
        std::io::stdout(),
        crossterm::style::SetBackgroundColor(crossterm::style::Color::Reset)
    );
    RocResult::ok(())
}

// -------------------------------- Thread --------------------------------

#[no_mangle]
pub extern "C" fn roc_fx_sleepSeconds(seconds: f64) -> RocResult<(), ()> {
    let duration = Duration::from_secs_f64(seconds);
    std::thread::sleep(duration);
    RocResult::ok(())
}
