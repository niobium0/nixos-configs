{
  config,
  pkgs,
  dimSeconds ? 10,
  dimStepSeconds ? 0.25,
  minBrightnessPercents ? 1,
}: let
  light = "${pkgs.light}/bin/light";
  dunstify = "${pkgs.dunst}/bin/dunstify";
  upower = "${pkgs.upower}/bin/upower";
  dimSeconds' = builtins.toString dimSeconds;
  dimStepSeconds' = builtins.toString dimStepSeconds;
  minBrightnessPercents' = builtins.toString minBrightnessPercents;
in
  pkgs.writeTextFile {
    name = "dim-screen";
    executable = true;
    destination = "/bin/dim-screen";
    text = ''
      #!${pkgs.python3}/bin/python3

      import os, signal, time

      def restore(sig, frame):
        print("Restoring brightness")
        os.system("${light} -I")
        os.system(f"${dunstify} --close {ARBITRARY_NOTIFICATION_ID}")
        exit(0)

      signal.signal(signal.SIGTERM, restore)
      signal.signal(signal.SIGINT, restore)

      steps = int(${dimSeconds'} / ${dimStepSeconds'})

      os.system('${light} -O') # Save state.
      brightness = float(os.popen('${light}').read()) # Get state.
      step = brightness / steps
      ARBITRARY_NOTIFICATION_ID = 3873
      start_time = time.time()
      while True:
        current_time = time.time()
        elapsed_time = current_time - start_time
        remaining_time = 15 - elapsed_time
        if remaining_time <= 0:
          break

        os.system(f"${light} -S {brightness}")
        os.system(f"${dunstify} --appname dim-screen --replace {ARBITRARY_NOTIFICATION_ID} 'Screen will be locked in {round(remaining_time)} seconds'")

        brightness -= step
        time.sleep(${dimStepSeconds'})

      os.system(f'${light} -S {${minBrightnessPercents'}}')
      os.system(f"${dunstify} --close {ARBITRARY_NOTIFICATION_ID}")

      if os.system('${upower} --dump | grep "online.*no"') == 0:
        print("Battery is discharging, invoke suspend")
        os.system("systemctl ${
        if builtins.elem "nohibernate" config.boot.kernelParams
        then "suspend"
        else "suspend-then-hibernate"
      }")

      signal.pause()
    '';
    checkPhase = ''
      ${pkgs.python3}/bin/python3 -m py_compile $out/bin/dim-screen
    '';
  }
