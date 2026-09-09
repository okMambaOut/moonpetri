///|
fn main {
  let args = @env.args()
  if args.length() < 3 {
    println("usage: moonpetri <validate|explore|fire|report> FILE [arguments]")
    @sys.exit(2)
    return
  }
  let input = @fs.read_file_to_string(args[2]) catch {
    _ => {
      println("error: unable to read input file")
      @sys.exit(2)
      return
    }
  }
  let options : Array[String] = []
  for i in 3..<args.length() {
    options.push(args[i])
  }
  match @petri.run_command(args[1], input, options) {
    Ok(text) => println(text)
    Err(errors) => {
      for error in errors {
        println("error: \{error.to_repr()}")
      }
      @sys.exit(2)
    }
  }
}
