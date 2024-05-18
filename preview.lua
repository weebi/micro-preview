VERSION = "1.0.0"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local fmt = import("fmt")

local preview_window, preview_command = nil

function init()
  -- Check if pandoc exists on system, disable plugin and warn user if it's missing.
  local _, error = shell.RunCommand("pandoc -v")
  if error ~= nil then
    micro.InfoBar():Error("Pandoc not found, install it to use the Preview plugin!")
    micro.Log(fmt.Sprintf("[Preview]: %s", 'Could not find Pandoc, add it to the path or install it using a package manager.'))
    return
  end

  -- These are the format options for pandoc.
  -- See "pandoc --list-output-formats/--list-input-formats" for the available options.
  config.RegisterCommonOption("preview", "input_format", "gfm")
  config.RegisterCommonOption("preview", "output_format", "plain")
  config.RegisterCommonOption("preview", "extra_args", "--reference-links --reference-location=document")

  -- Assemble preview_command from config. This could probably be done much neater.
  local input_format, output_format, extra_args = nil
  preview_command = fmt.Sprintf("pandoc %s -r %s -w %s",
                      config.GetGlobalOption("preview.extra_args"),
                      config.GetGlobalOption("preview.input_format"),
                      config.GetGlobalOption("preview.output_format"))

  config.MakeCommand("preview", doPreview, config.NoComplete)
  -- config.AddRuntimeFile("preview", config.RTHelp, "help/markdown-preview.md")
end

function buildView(data)
  -- If a preview window already exists, we can just replace its
  -- contents instead of recreating it entirely from scratch.
  if preview_window ~= nil then
    -- This is a mildly rushed solution.
    preview_window.Buf.EventHandler:Remove(preview_window.Buf:Start(), preview_window.Buf:End())
    preview_window.Buf.EventHandler:Insert(buffer.Loc(0, 0), data)
    return
  else
    -- Make a new vsplit pane to put the given preview data into and save it for later.
    micro.CurPane():VSplitIndex(buffer.NewBuffer(data, "preview"), true)
    preview_window = micro.CurPane()

    -- Make window read-only and disable saving.
    preview_window.Buf.Type.Scratch = true
    preview_window.Buf.Type.Readonly = true

    -- Disable ruler, autosave and change statusformats for the preview pane.
    preview_window.Buf:SetOptionNative("ruler", false)
    preview_window.Buf:SetOptionNative("autosave", false)
    preview_window.Buf:SetOptionNative("statusformatr", "")
    preview_window.Buf:SetOptionNative("statusformatl", "Preview")

    -- The primary pane should always wider than the preview pane.
    -- (what does this even accept? cols?)
    micro.CurPane():ResizePane(85)
  end
end

-- This is probably not very resource efficient,
-- but check if there are any preview windows present.
-- If there is, try doPreview again.
function onSave(bp)
  if bp.Buf:FileType() == "markdown" then
    if preview_window ~= nil then
      doPreview(bp)
    end
  end
end

-- If the preview pane is closed, we can free the
-- preview_window variable so we can reuse it again.
function onQuit(bp)
  if preview_window ~= nil then
    if bp.ID == preview_window.ID then
      micro.InfoBar():Message("Preview window closed.")
      preview_window = nil
    end
  end
end

function doPreview(bp)
  if bp.Buf:FileType() ~= "markdown" then
    micro.InfoBar():Error("Not a markdown file!")
    return
  else
    bp:Save()

    -- Append the current file name/path to the preview command, then run it
    -- this should probably be sanitized to prevent cursed strings.
    local command = fmt.Sprintf("%s %s", preview_command, bp.Buf.Path)
    local data, error = shell.RunCommand(command) -- This *might* cause issues with large files in the future!

    if error ~= nil then
      micro.InfoBar():Error(error)
      micro.Log(error)
      return
    end

    -- Feed the data to the view builder.
    buildView(data)
  end
end
