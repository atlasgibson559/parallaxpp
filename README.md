# Parallax Framework

**Parallax** is a lightweight, modular roleplay framework built for Garry's Mod. It is designed from the ground up to give serious roleplay communities the tools they need to build stable, flexible, and immersive experiences. Parallax focuses on performance, clean structure, and full control for developers who want to avoid the clutter and legacy issues of older frameworks.

Whether you're creating a Half-Life universe roleplay, a military server, a modern city setting, or something completely original, Parallax gives you the foundation to bring your ideas to life.

---

## Features

Parallax comes with a wide range of features that are useful for developers and server owners:

* **Modular Architecture**
  Code is separated into small, independent modules that make it easier to maintain, update, and debug. Each system only does one job, making it easier to extend or replace.

* **Custom UI System**
  A fully customizable user interface system inspired by Valve's Gamepad UI design, allowing developers to build immersive menus and HUDs that match the tone of their server.

* **Inventory System**
  Items are stored based on weight rather than slots. This system allows more realism, as players need to consider the size and weight of what they carry rather than just a fixed number of items.

* **Database Support**
  Built-in support for both SQLite and MySQL. This makes it possible to run development tests offline with SQLite and switch to MySQL for live servers.

* **Secure Networking**
  Parallax includes a custom networking layer that compresses and encrypts data, reducing lag and preventing client-side exploits or sniffing.

* **Schema System**
  Items, factions, classes, and more can be defined through simple Lua files inside your schema. This makes it easy to separate content from the framework and keep things organized.

* **Enforced Code Standards**
  All code is written using K\&R Lua formatting and documented with LDoc, making it easy to read and modify even after a long time.

---

## Installing Parallax

To install Parallax on your server or for local testing, follow these steps carefully:

1. Download or clone the Parallax core framework and place it in your `garrysmod/gamemodes/` folder.
2. Clone or create a schema. The schema folder should be placed in the same `gamemodes/` directory, alongside the core.
3. The schema must include a `gamemode/` directory containing the schema's code and configuration.
4. Make sure both folders are named clearly (e.g., `parallax` for the core and `parallax-skeleton` for your schema).
5. Start Garry's Mod and select the schema from the menu, or set it in your server configuration file for multiplayer hosting.

Example layout:

```
garrysmod/
└── gamemodes/
    ├── parallax/
    └── parallax-skeleton/
```

This setup keeps the framework and your custom content fully separate, making updates and maintenance much easier.

---

## Repositories

Parallax is split across different repositories to keep things clean and organized:

* [`parallax`](https://github.com/Parallax-Framework/parallax): The core of the framework. All essential features and base systems live here.
* [`parallax-skeleton`](https://github.com/Parallax-Framework/parallax-skeleton): A blank schema template for developers to use as a starting point.

> Some repositories may remain private while development continues. Public releases will be announced when ready.

---

## Who Is This For?

Parallax was made for those who want full control of their server code without dealing with bloated frameworks or outdated systems. This includes:

* Server owners who want to create immersive and serious RP environments.
* Developers looking for a clean and organized codebase to build on.
* Communities that care about long-term support, updates, and readable code.

Whether you're a solo developer or part of a larger team, Parallax gives you a modern foundation with room to grow.

---

## Contributing

We welcome contributions from the community. If you want to help improve Parallax, here's how to get started:

1. Fork the repository and make your changes in a separate branch.
2. Follow the [Parallax style guide](https://github.com/Parallax-Framework/.github/blob/main/STYLE.md) for formatting and structure.
3. Test your changes in both singleplayer and multiplayer where possible.
4. Add LDoc comments for new functions, modules, or systems.
5. Open a pull request and describe your changes clearly.

We aim to keep the framework clean and stable, so code quality matters. Take your time and double-check your work before submitting.

---

## Framework Integrity

If you notice code that looks copied from another framework or too similar to outside projects, please report it. We take originality seriously and want to avoid reusing or borrowing from other work without proper permission.

Creating something from scratch means a lot to us, and we want to make sure everything included in Parallax is either original or clearly credited.

---

## License & Credit Requirements

Parallax is released under the [MIT License](LICENSE). This means it is free to use, modify, and distribute — but with conditions.

**You must provide proper credit** when using any part of this framework. This includes:

* Keeping the license header at the top of all original files.
* Clearly mentioning that your work is based on the Parallax Framework in your own README or documentation.
* Not claiming the framework or its features as your own.

Ignoring these rules is a violation of the license and may result in further action.

---

## Contact

For questions, help, or to stay updated on development:

* Open an issue or pull request on the GitHub repository
* Join the [community Discord server](https://discord.gg/yekEvSszW3)