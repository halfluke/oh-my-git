<img src="https://github.com/git-learning-game/oh-my-git/blob/main/images/oh-my-git.png" width="400">

**Oh My Git!** is an open-source game about learning Git!

> **Unofficial fork.** This repository is a community-maintained fork of [Oh My Git!](https://github.com/git-learning-game/oh-my-git) by [blinry](https://github.com/blinry) and [bleeptrack](https://github.com/bleeptrack). Upstream home: [git-learning-game/oh-my-git](https://github.com/git-learning-game/oh-my-git).
>
> You are on the **`main`** branch (Godot **3.x**). The **`godot4`** branch is the Godot **4.6** port with the same **Beyond Git** content. Questions or feedback about this fork: comment on [upstream issue #237](https://github.com/git-learning-game/oh-my-git/issues/237).

### Branches

| Branch | Engine | Notes |
|--------|--------|--------|
| **`main`** | Godot 3.x | This branch; play from source below or use [official itch.io builds](https://blinry.itch.io/oh-my-git). |
| **`godot4`** | Godot 4.6 | Port + Beyond Git; see [`godot4` README](https://github.com/halfluke/oh-my-git/blob/godot4/README.md). |

## Play the game

This fork does **not** ship release binaries for the **Beyond Git** additions.

- **Official Godot 3 builds:** [itch.io](https://blinry.itch.io/oh-my-git) (upstream; does not include this fork's extra levels unless you run from source here).
- **This branch from source:**
  1. Install [Godot 3.x](https://godotengine.org/download/3.x).
  2. Clone this repo on **`main`**: `git clone -b main https://github.com/halfluke/oh-my-git.git` (or `git checkout main`).
  3. Open **`project.godot`** in the editor and press **F5**, or run `godot3 project.godot` from the repo root (on Debian/Ubuntu the binary is often `godot3`; some systems use `godot`).

## Beyond Git

In the **Play** level list, extra **Beyond Git** reading sections (GitHub, GitLab, Gitea, Bitbucket + Jira, Azure DevOps, and related platform theory) appear grouped at the bottom after the main Git tutorial chapters:

![Level select: Beyond Git sections in the menu](images/readme-beyond-git-level-menu.png)

## About upstream maintenance

The original [Oh My Git!](https://github.com/git-learning-game/oh-my-git) is in **low-maintenance** mode; large upstream pull requests may take a long time. This fork is maintained independently for **Beyond Git** and the **`godot4`** port—use [issue #237](https://github.com/git-learning-game/oh-my-git/issues/237) for feedback on this fork.

## Report bugs

- **This fork (Beyond Git, Godot 3 branch):** comment on [upstream issue #237](https://github.com/git-learning-game/oh-my-git/issues/237).
- **Original Oh My Git! game:** use the [upstream issue tracker](https://github.com/git-learning-game/oh-my-git/issues).

## Build your own level!

Wanna build your own level? Great! Here's how to do it:

1. Download the latest [Godot **3.x**](https://godotengine.org/download/3.x) editor (this branch; Godot 4 is on the **`godot4`** branch).
2. Clone this repository and stay on **`main`**.
3. Run the game—the easiest way is `godot3 scenes/main.tscn` from the project directory (or `godot` where that is your Godot 3 binary).
4. Get a bit familiar with the levels which are currently there.
5. Take a look into the `levels` directory. It's split into chapters, and each level is a file.
6. Make a copy of an existing level or start writing your own. See the documentation of the format below.
7. Write and test your level. For this fork, discuss in [#237](https://github.com/git-learning-game/oh-my-git/issues/237); upstream may accept PRs for the original game separately.

### Level format

```
title = This is the level's title

[description]

This text will be shown when the level starts.

It describes the task or puzzle the player can solve.

[cli]

(optional) This text will be shown below the level description in a darker color.

It should give hints to the player about command line usage and also maybe some neat tricks.

[congrats]

This text will be shown after the player has solved the level.

Can contain additional information, or bonus exercises.

[setup]

# Bash commands that set up the initial state of the level. An initial
# `git init` is always done automatically. The default branch is called `main`.

echo You > people_who_are_awesome
git add .
git commit -m "Initial commit"

[win]

# Bash commands that check whether the level is solved. Write these as if you're
# writing the body of a Bash function. Make the function return 0 if it's
# solved, and a non-zero value otherwise. You can use `return`, and also, Bash
# functions return the exit code of the last statement, which sometimes allows
# very succinct checks. The comment above the win check will be shown in the game
# as win condition text.

# Check whether the file has at least two lines in the latest commit:
test "$(git show HEAD:people_who_are_awesome | wc -l)" -ge 2
```

A level can consist of multiple repositories. To have more than one, you can use sections like `[setup <name>]` and `[win <name>]`, where `<name>` is the name of the remote. The default name is "yours". All repositories will add each other as remotes. Refer to the [remote](levels/remotes) levels examples.

## Contribute code!

To open the game in the [Godot editor](https://godotengine.org), run `godot3 project.godot`. You can then run the game using *F5*.

> **First-run note:** The `.import/` directory is gitignored. Open the project in the Godot 3 editor at least once before running from the command line, so assets (sounds, images, etc.) are imported correctly.

Maintenance of Beyond Git on **`main`** and the Godot 4 port on **`godot4`** happens in this fork; coordinate in [#237](https://github.com/git-learning-game/oh-my-git/issues/237) before large `*.tscn` edits.

To build your own binaries, install Godot 3 [export templates](https://docs.godotengine.org/en/stable/getting_started/workflow/export/exporting_projects.html), plus `zip`, `wget`, and `7z`, then run `make`. On Debian/Ubuntu the Godot binary is often `godot3`—adjust paths in the Makefile if needed.

## Code of Conduct

We have a [Code of Conduct](CODE_OF_CONDUCT.md) in place that applies to all project contributions, including issues and pull requests.

## Funding

The original game received funding for six months in 2020/2021 from the [Prototype Fund](https://www.prototypefund.de). Thanks!

<a href="https://www.bmbf.de/en/"><img src="https://www.dipf.de/en/images/BMBF_4C_M_e.jpg/@@download/image/BMBF_4C_M_e.jpg" alt="Logo of the German Ministry for Education and Research" height="100px"></a>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href="https://prototypefund.de/en/"><img src="https://raw.githubusercontent.com/prototypefund/ptf-ci/main/logos/PrototypeFund-Icon.svg" alt="Logo of the Prototype Fund" height="100px"></a>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href="https://okfn.de/en/"><img src="https://upload.wikimedia.org/wikipedia/commons/4/4d/Open_Knowledge_Foundation_Deutschland_Logo.svg" alt="Logo of the Open Knowledge Foundation Germany" height="100px"></a>

## Thanks

- "success" sound by [Leszek_Szarzy, CC0](https://freesound.org/people/Leszek_Szary/sounds/171670/)
- "swish" sound by [jawbutch, CC0](https://freesound.org/people/jawbutch/sounds/344408/)
- "swoosh" sound by [WizardOZ, CC0](https://freesound.org/people/WizardOZ/sounds/419341/)
- "poof" sound by [Saviraz, CC0](https://freesound.org/people/Saviraz/sounds/512217/)
- "buzzer" sound by [Loyalty_Freak_Music, CC0](https://freesound.org/people/Loyalty_Freak_Music/sounds/407466/)
- "typewriter_ding" sound by [_stubb, CC0](https://freesound.org/people/_stubb/sounds/406243/)

## License

[Blue Oak Model License 1.0.0](LICENSE.md) – a [modern alternative](https://writing.kemitchell.com/2019/03/09/Deprecation-Notice.html) to the MIT license. It's a a pleasant read! :)
