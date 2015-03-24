import std.stdio;
import std.range;
import std.format;
import std.datetime;
import core.sys.posix.unistd;
import core.sys.posix.sys.ioctl;

import core.thread;

class Progress
{
  private:

    immutable static size_t default_width = 80;
    size_t width = default_width;

    ulong start_time;
    string caption = "Progress";
    size_t iterations;
    size_t counter;


    this(size_t iterations) {
      if(iterations <= 0) iterations = 1;

      counter = 0;
      this.iterations = iterations;
      start_time = Clock.currTime.toUnixTime;
    }


    size_t getTerminalWidth() {
      size_t column;
      winsize ws;
      if(ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) != -1) {
        column = ws.ws_col;
      }
      if(column == 0) column = 20;

      return column;
    }


    void clear() {
      write("\r");
      for(auto i = 0; i < width; i++) write(" ");
      write("\r");
    }


    int calc_eta() {
      immutable auto ratio = cast(double)counter / iterations;
      auto current_time = Clock.currTime.toUnixTime();
      auto duration = (current_time - start_time);
      int hours, minutes, seconds;
      double elapsed = (current_time - start_time);
      int eta_sec = cast(int)((elapsed / ratio) - elapsed);

      return eta_sec;
    }


    void print() {
      immutable auto ratio = cast(double)counter / iterations;
      auto eta_text = "--:--:-- ";

      // ETA
      if(counter <= 1 || ratio == 0.0) {
      } else {
        int eta_sec = calc_eta();
        auto d = dur!"seconds"(eta_sec);
        int h, m, s;
        d.split!("hours", "minutes", "seconds")(h, m, s);
        auto writer = appender!string();
        formattedWrite(writer, "%02d:%02d:%02d ", h, m, s);
        eta_text = writer.data;
      }

      // header text
      auto header_writer = appender!string();
      formattedWrite(header_writer, "%s %3d%% |", caption, cast(int)(ratio * 100));
      immutable auto title_text = header_writer.data;

      // footer text
      immutable auto eta_header_text = "| ETA: ";
      immutable auto right_margin = eta_header_text.length + eta_text.length + 1;

      write(title_text);

      double current = ratio * width;
      size_t i = title_text.length + 5;
      auto bar_length = width - right_margin;
      for(; i < current && i < bar_length; i++) write("o");
      for(; i < bar_length; i++) write(" ");

      write(eta_header_text, eta_text);
    }

    void update() {
      width = getTerminalWidth();
 
      clear();

      print();
      stdout.flush();
    }

  public:

    @property {
      string title() { return caption; }
      string title(string text) { return caption = text; }
    }

    @property {
      size_t count() { return counter; }
      size_t count(size_t val) {
        if(val > iterations) val = iterations;
        return counter = val;
      }
    }

    void reset() {
      counter = 0;
      start_time = Clock.currTime.toUnixTime;
    }

    void next() {
      counter++;
      if(counter > iterations) counter = iterations;

      update();
    }


}

void main(string[] args) {
  size_t iteration = 100;
  Progress p = new Progress(iteration);
  for(int i = 0; i < iteration; i++) {
    p.next();
    Thread.sleep(dur!("msecs")(80));
  }
  writeln();
}

