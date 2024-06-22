---
layout: post
title: High Performance PostgreSQL for Rails
date: 2024-06-22 17:16:00 +0300
tags: general, rails, postgres
---

![book cover](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/aapsql-500.jpg)

This June I read this awesome book and definitly recommend to anyone, regardless of beign a Rails developer or not.

Most of the Rails developers tend to skip database basics and column types and this common behaviour sticks with them. But I don't it is their fault, or atleast they are not that much guilty of not digging deep.
Rails is awesome. No doubt with it. So far, it is the best framework I ever saw. Everything feels natural and it just works. Yet this "just works" mindset comes with a bad cost in the end. Most of the projects that I worked on didn't really leveraging power of the Postgres.

You can buy the book from this [link](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/)

## No-ORM

Even tough ActiveRecord is a beast and killer, at certain point every project needs good old raw SQL. And the problem is that, ORM's and SQL kind of doing the same thing. So at the end we need to learn two different syntaxes and functions to
achieve same result. I mean isn't it kind of waste of time to both learn how to query in ActiveRecord and SQL? Using ORM is easy and almost seamless. But doing complex things with it, no thanks. It becomes so awkward that using raw SQL
feels more clean.

## What I learned from this book?

- I, kind of, developed a stance against ORMs and my POV changed a bit with this book.
- Using GUI is great, but I should use `psql` more often.
- Postgres is powerful, really it is. Use it's power.
- Not every type and concept supported by ActiveRecord and it is sucks.
- Indexes are not only for retrieving stuff rapidly. They serve different purposes and tailoring indexes are important. Here an index, there an index is not a good approach.
- PgBouncer and reverse-proxies for Postgres.
