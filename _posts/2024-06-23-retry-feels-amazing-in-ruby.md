---
layout: post
title: Retry feels amazing in Ruby!
date: 2024-06-23 21:31:00 +0300
tags: ruby
---

It will be a small post, but I wanted to share it anyway. I mainly use Golang and Ruby, and these languages have different approaches to errors and how they are handled.
I could say Ruby follows usual try catch pattern, the interesting one is Go's approach, actually.

When you receive an error in Ruby it halts the program, but in Go, it does not. Programmers have to handle it.

Honestly, sometimes it can be tedious to write `if err != nil` but overall I mostly enjoy Go's error mechanism and how it is simple.
All you need is to satisfy `Error` interface. And, if you are not interested in the outcome of the command you executed, you can simply ignore the error.

On the other hand, Ruby is so elegant that makes your day. I wrote a demonstration code that retries
and waits an amount equal to the elements of the Fibonacci sequence.

```ruby
class FibonacciSequence
  def initialize
    @numbers = Enumerator.produce([1, 2]) do |a, b|
      [a+b, b+1]
    end.lazy
  end

  def next = @numbers.next.first
end

def work
  retry_count = 0
  sequence = FibonacciSequence.new

  begin
    # ...
    puts "I'll do something"

    raise StandardError.new("oopsies") if [true, false].sample
  rescue StandardError
    if retry_count <= 4
      wait_for = sequence.next
      retry_count += 1

      puts "I'll wait for #{wait_for} seconds and try again."
      sleep(wait_for)

      retry
    end

    puts "Retried #{retry_count} times."
  end
end
```
