process.signal"kill-nscd"{
    signal = "SIGTERM",
    exe = "/usr/sbin/nscd"
}
shell.command"/bin/touch /tmp/NSCD-NOT-RUNNING"{
    handle = "nscd-not-running"
}
process.running"/usr/sbin/nscd"{
    require = [[process.signal("kill-nscd")]],
    notify_failed = "nscd-not-running"
}
