# lsmm
Linux server manager Manager

# About
lsmm is a small utility script to save me from having to keep trying to reconnet the servers telnet console by hand after restarting it
servers meaning [these](https://gameservermanagers.com)

# Usage

## Start "Monitor"
The Class takes the name of the linux game server manager script and the corresponding telnet password

```ruby
sm = ServerManager.new "script name","password"
sm.monitor
```

Example for 7 Days to die:
```ruby
sm = ServerManager.new "sdtdserver", "password"
sm.monitor
```

## Monitor Interface Commands

| Command  | Description |
|--------- |-------------|
|r[restart]| Restarts the server and reconnects the telnet session|
|q[uit]| Quits the Monitor|
|server \<command\>| execute \<command\> on the game server|


# ToDo

* Stop command
