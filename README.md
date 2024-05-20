# Micro-preview

-----

A very simple plugin for the [Micro](https://github.com/zyedidia/micro) editor to preview markdown using [Pandoc](https://github.com/jgm/pandoc).

Pandoc is also the only external dependency needed to run this plugin. I've mainly used and tested this using the latest versions of Micro, so your mileage might vary on other versions.

## Installation

### Settings

Add this repo as a **pluginrepos** option in the **~/.config/micro/settings.json** file (it is necessary to restart the micro after this change):

```json
{
  "pluginrepos": [
      "https://raw.githubusercontent.com/weebi/micro-preview/master/repo.json"
  ]
}
```

### Install

In your micro editor press **Ctrl-e** and run command:

```
> plugin install preview
```

or run in your shell

```sh
micro -plugin install preview
```

## Usage

When installed, the plugin creates the `preview` command which splits the window vertically and opens a pane on the right side containing the converted markdown.

The preview window *should* update every time you save, but can also be forcibly updated by running `preview` again.

## Configuration

For now, the default configuration looks like this:

```json

{
  "preview.input_format": "gfm",
  "preview.output_format": "plain",
  "preview.extra_args": "--reference-links --reference-location=document"
}

```

All of the possible values for `input_format` and `output_format` can be listed using `pandoc --list-output-formats` and `pandoc --list-input-formats`.

The value for `extra_args` can be anything from `pandoc --help`.
