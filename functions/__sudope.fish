function __sudope -d "Quickly toggle sudo prefix"

  # Save the current command line and cursor position.
  set -l command_buffer (commandline)
  set -l cursor_position (commandline -C)

  # If the command line is empty, pull the last command from history.
  if test -z "$command_buffer"
    set command_buffer $history[1]
  end

  # Parse the command line (first line only).
  set -l command_parts (string match -r -- '^(\s*)(sudo(\s+|$))?(-e(\s+|$))?(vim(\s+|$))?(.*)' $command_buffer[1])

  # Handle multiline commands with extra care.
  set -l command_lines_count (count $command_buffer)
  test $command_lines_count -gt 1
    and set -l command_rest $command_buffer[2..$command_lines_count]

  if string match -qr '^sudo\s*$' $command_parts[3]
    # "sudo" is present in the beginning of the command.

    set -l new_cmd $command_parts[2 5..]
    
    # 'sudo -e'
    if string match -qr -- '^-e\s*$' $command_parts[5]
      set new_cmd $command_parts[2] 'vim' $command_parts[6..]
    end

    # Remove "sudo", leave any leading whitespace (if present).
    commandline -r (string join \n (string join '' $new_cmd) $command_rest)

    # Push the cursor position back if appropriate ('sudo' and whitespace).
    set -l lead_length (string length -- "$command_parts[2]")
    set -l sudo_length (string length -- "$command_parts[3]")
    if test $cursor_position -ge (math $lead_length+$sudo_length)
      # The cursor was after "sudo".
      set cursor_position (math $cursor_position-$sudo_length)
    else if test $cursor_position -ge $lead_length
      # The cursor was somewhere on "sudo".
      set cursor_position $lead_length
    end

    # Place the cursor where it was (or where it should be).
    commandline -C -- $cursor_position
  else
    # No "sudo".
    
    set -l new_cmd $command_parts[2] 'sudo ' $command_parts[3..]

    # 'vim ...'
    if string match -qr '^vim\s*$' $command_parts[3]
      set new_cmd $command_parts[2] 'sudo -e' $command_parts[4..]
    end

    # Add "sudo" to the beginning of the command, after any leading whitespace (if present).
    commandline -r (string join \n (string join '' $new_cmd) $command_rest)

    # Push the cursor position ahead if necessary (+5 for 'sudo ').
    test $cursor_position -ge (string length -- "$command_parts[2]")
      and set cursor_position (math $cursor_position+5)

    # Place the cursor where it was (or where it should be).
    commandline -C $cursor_position
  end
end
