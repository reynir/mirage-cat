# Mirage-cat

Mirage-cat is a proof of concept of how to exploit solo5-hvt's support for file descriptors for network devices for other purposes. The unikernel is able to read from stdin - something that is otherwise not supported on solo5.

## Usage

The simplest way to call mirage-cat is using `--net:stdin=@0`:

    $ solo5-hvt --net:stdin=@0 ./dist/cat.hvt
                |      ___|
      __|  _ \  |  _ \ __ \
    \__ \ (   | | (   |  ) |
    ____/\___/ _|\___/____/
    Solo5: Bindings version v0.7.5
    Solo5: Memory map: 512 MB addressable:
    Solo5:   reserved @ (0x0 - 0xfffff)
    Solo5:       text @ (0x100000 - 0x1ebfff)
    Solo5:     rodata @ (0x1ec000 - 0x224fff)
    Solo5:       data @ (0x225000 - 0x2dafff)
    Solo5:       heap >= 0x2db000 < stack < 0x20000000
    2023-05-01 17:50:42 -00:00: INF [netif] Plugging into stdin with mac 8a:45:9b:32:b9:df mtu 1500
    Hello, World!
    Hello, World!

However, both the solo5 bindings and mirage-net-solo5 library are quite chatty as can be seen in the above output. It is therefore recommended to quiet down the chatty bits:

    $ solo5-hvt --net:stdin=@0 ./dist/cat.hvt --solo5:quiet -l netif:quiet
    Hello, World!
    Hello, World!

## How it works

This exploits solo5's ability to pass file descripts as network devices. This was originally added in order to run the solo5 tender with less privileges by opening the network device (through `/dev/net/tun`) and then dropping `CAP_NETADMIN` before exec'ing solo5-hvt for example when running solo5 in a docker container.

From the solo5 tender's point of view what you have is just a file descriptor and `read(2)` and `write(2)` are exposed. The only limitation is that solo5-hvt needs to be able to set `O_NONBLOCK` with `fcntl(2)`. While the solo5 bindings expose `read(2)` and `write(2)` in Mirage these hypercalls are not exposed directly. Instead you have `write` and `listen` defined in [mirage-net](https://github.com/mirage/mirage-net/blob/3f75f8afbbc4b11536a04cd45eb95f46c9b5210b/src/mirage_net.mli#L60-L73).

```OCaml
val write: t -> size:int -> (Cstruct.t -> int) -> (unit, error) result Lwt.t
(** [write net ~size fill] allocates a buffer of length [size], where [size]
   must not exceed the interface maximum packet size ({!mtu} plus Ethernet
   header). The allocated buffer is zeroed and passed to the [fill] function
   which returns the payload length, which may not exceed the length of the
   buffer. When [fill] returns, a sub buffer is put on the wire: the allocated
   buffer from index 0 to the returned length. *)

val listen: t -> header_size:int -> (Cstruct.t -> unit Lwt.t) -> (unit, error) result Lwt.t
(** [listen ~header_size net fn] waits for a [packet] with size at most
   [header_size + mtu] on the network device. When a [packet] is received, an
   asynchronous task is created in which [fn packet] is called. The ownership
   of [packet] is transferred to [fn].  The function can be stopped by calling
   {!disconnect}. *)
```

This provides a pretty terrible experience for reading and writing to a file descriptor.
The hyper calls could be exposed directly, but this would require implementing a new device.

## Limitations

I have not figured a way to detect end of file. Instead, when end of file is reached the unikernel goes into an infinite loop.

    $ uptime | solo5-hvt --net:stdin=@0 ./dist/cat.hvt --solo5:quiet -l netif:quiet
     20:01:32 up 1 day, 23:13,  1 user,  load average: 0.81, 0.77, 0.85
    ^Csolo5-hvt: Exiting on signal 2
