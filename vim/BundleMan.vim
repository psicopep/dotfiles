" ===================
"    Configuration
" ===================

" [ Parameters ]

" Location of vimfiles directory where to install bundles
" Could be either:
" HOME: location will be $HOME/.vim or $HOME/vimfiles depending on Linux or Windows
" VIM: location will be $VIM/vimfiles
" Path: location will be the path given (don't use trailing slashes)
"       (relative path will be considered relative to the BundleMan script location)
let VIMFILES = 'vimfiles'

" Take ownership of vimfiles directory
" Could be either:
" 1: Enforce bundles listed == bundles in vimfiles.
"    If a bundle is not listed in either BundleList or IgnoreList it gets uninstalled.
" 0: Ignore bundles not listed (BundleMan does not own them).
let TAKE_OWNERSHIP = 1


" [ List of bundles to install / update ]

function BundleList()
Bundle { url: "https://github.com/zacanger/angr.vim" }
Bundle { url: "https://github.com/davidhalter/jedi-vim", pre_install: "HasPython", post_install: "DownloadJedi" }
Bundle { url: "https://github.com/psicopep/simpletree" }
Bundle { url: "https://github.com/tpope/vim-commentary" }
Bundle { url: "https://github.com/tpope/vim-surround" }
" [ Additional languages support ]
" Bundle { url: "https://github.com/OmniSharp/omnisharp-vim", pre_install: "CheckOmnisharpRequirements", post_install: "BuildOmnisharpServer" }
" Bundle { url: "https://github.com/Rip-Rip/clang_complete" }
" Bundle { url: "https://github.com/artur-shaik/vim-javacomplete2" }
" Bundle { url: "https://github.com/vim-pandoc/vim-pandoc" }
" Bundle { url: "https://github.com/vim-pandoc/vim-pandoc-syntax" }
" [ Colorschemes ]
" Bundle { url: "https://github.com/romainl/Apprentice" }
" Bundle { url: "https://github.com/tokers/magellan" }
" Bundle { url: "https://github.com/dikiaap/minimalist" }
" Bundle { url: "https://github.com/NLKNguyen/papercolor-theme" }
" Bundle { url: "https://github.com/Siltaar/primaries.vim" }
" Bundle { url: "https://github.com/Lokaltog/vim-distinguished", branch: "develop" }
" [ Tools to consider ]
" Bundle { url: "https://github.com/mMontu/VimCalc" }
" vimproc is required by vim-vebugger
" Bundle { url: "https://github.com/Shougo/vimproc.vim", post_install: "VimProcBuild" }
" Bundle { url: "https://github.com/idanarye/vim-vebugger" }
" Bundle { url: "https://github.com/will133/vim-dirdiff" }
" Bundle { url: "https://github.com/Shougo/vinarise.vim" }
" Bundle { url: "https://github.com/diepm/vim-rest-console" }
" [ Deprecated (keep them listed in case we change our minds) ]
" Bundle { url: "https://github.com/bkad/CamelCaseMotion" }
" Bundle { url: "https://github.com/justinmk/vim-sneak", post_install: "PatchVimSneak" }
" Bundle { url: "https://github.com/Yggdroot/indentLine" }
" Bundle { url: "https://github.com/ctrlpvim/ctrlp.vim" }
" Bundle { url: "https://github.com/majutsushi/tagbar" }
" Bundle { url: "https://github.com/Shougo/neocomplcache.vim" }
" Bundle { url: "https://github.com/Shougo/neocomplete.vim" }
" Bundle { url: "https://github.com/airblade/vim-rooter" }
" Bundle { url: "https://github.com/FelikZ/ctrlp-py-matcher" }
" Bundle { url: "https://github.com/klen/python-mode", post_install: "LeaveOnlyPymodeSyntax" }
endfunction

" [ List of bundles in vimfiles to ignore (bundles manually managed) ]

function IgnoreList()
endfunction


" [ Pre/Post install functions ]

function HasPython()
  return has('python3') || has('python')
endfunction

function DownloadJedi(install_dir)
  call s:InstallRepo("https://github.com/davidhalter/jedi", 'a79a1fbef57564d031c59f47def20a6d9adf3439', a:install_dir . "/pythonx/jedi", "jedi")
  call s:InstallRepo("https://github.com/davidhalter/parso", 'e6bc924fbabbfa3090044e475c91a7655b9c6e9b', a:install_dir . "/pythonx/parso", "parso")
endfunction

function CheckOmnisharpRequirements()
  let result = 0
  if has("win32") || has('win64')
    let msbuildFound = system('dir c:\Windows\Microsoft.NET\Framework\msbuild.exe /b /s')
    if msbuildFound =~ '.\+v4.\+'
      let result = 1
    else
      echo "No .Net 4.0+ msbuild.exe found! Msbuild required to build OmniSharp Server."
    endif
  else
    if executable('mono')
      let result = 1
    else
      echo "Mono not found! Mono required to build OmniSharp Server."
    endif
  endif
  return result
endfunction

function BuildOmnisharpServer(install_dir)
  let server_dir = a:install_dir . "/server"
  if has("win32") || has('win64')
    " Download server
    call s:InstallRepo("https://github.com/OmniSharp/omnisharp-server", 'master', server_dir, '')
    call s:InstallRepo("https://github.com/icsharpcode/NRefactory", 'master', server_dir . "/NRefactory", '')
    call s:InstallRepo("https://github.com/jbevain/cecil", 'master', server_dir . "/cecil", '')
    " Build server
    let server_dir = substitute(server_dir, '/', '\', 'g')
    call system("cmd /C \"cd " . server_dir . " & msbuild OmniSharp.sln\"")
    " Erase everything except the built server
    call system("move " . server_dir . "\\OmniSharp\\bin " . server_dir . "\\keep_bin")
    for subdir in [".nuget", "cecil", "Microsoft.Build.Evaluation", "NRefactory", "OmniSharp", "OmniSharp.Tests", "packages"]
      call system("rmdir " . server_dir . "\\" . subdir . " /s /q")
    endfor
    call system("del " . server_dir . "\\*.* /q")
    call system("mkdir " . server_dir . "\\OmniSharp")
    call system("move " . server_dir . "\\keep_bin " . server_dir . "\\OmniSharp\\bin")
  endif
endfunction

let s:VIM_SNEAK_PATCH  = ["  \"NOTE: Added to fix a problem with IndentLines"]
let s:VIM_SNEAK_PATCH += ["  \"Reset IndentLines, as streak mode breaks it"]
let s:VIM_SNEAK_PATCH += ["  if exists(':IndentLinesReset')"]
let s:VIM_SNEAK_PATCH += ["    exec 'IndentLinesReset'"]
let s:VIM_SNEAK_PATCH += ["  endif"]

function PatchVimSneak(install_dir)
  " Patch to add reset of IndentLines as Label (old Streak) mode breaks it
  " The above patch code will be inserted at the end of after() function in streak.vim
  let streak_file = a:install_dir . "/autoload/sneak/label.vim"
  let lines = readfile(streak_file)
  let insert_index = -1
  let index = 0
  while index < len(lines)
    if lines[index] =~ '^fun\S\+\s\+s:after'
      break
    endif
    let index += 1
  endwhile
  while index < len(lines)
    if lines[index] =~ '^endf'
      let insert_index = index
      break
    endif
    let index += 1
  endwhile
  let lines = lines[:(insert_index - 1)] + s:VIM_SNEAK_PATCH + lines[insert_index :]
  call writefile(lines, streak_file)
endfunction

let s:PYMODE_AUTOLOAD  = ["fun! pymode#default(name, default)"]
let s:PYMODE_AUTOLOAD += ["    if !exists(a:name)"]
let s:PYMODE_AUTOLOAD += ["        let {a:name} = a:default"]
let s:PYMODE_AUTOLOAD += ["        return 0"]
let s:PYMODE_AUTOLOAD += ["    endif"]
let s:PYMODE_AUTOLOAD += ["    return 1"]
let s:PYMODE_AUTOLOAD += ["endfunction"]

function LeaveOnlyPymodeSyntax(install_dir)
  let is_windows = s:IsWindows()
  " Delete everything except syntax files
  let items = glob(a:install_dir . '/*', 1, 1) + glob(a:install_dir . '/.[^.]*', 1, 1)
  for item in items
    if item =~ 'syntax$'
      continue
    endif
    if isdirectory(item)
      if is_windows
        let item = substitute(item, '/', '\', 'g')
        call system("rmdir " . item . " /s /q")
      else
        call system("rm -r " . item)
      endif
    else
      call delete(item)
    endif
  endfor
  " Create minimal autoload file to support syntax files
  call mkdir(a:install_dir . "/autoload")
  let autoload_file = a:install_dir . "/autoload/pymode.vim"
  call writefile(s:PYMODE_AUTOLOAD, autoload_file)
endfunction

function VimProcBuild(install_dir)
  if s:IsWindows()
    let l:dll = "vimproc_win32.dll"
    if has('win64')
      let l:dll = "vimproc_win64.dll"
    endif
    let l:url = "https://github.com/Shougo/vimproc.vim/releases/download/ver.9.2/" . l:dll
    call s:DownloadFile(l:url, a:install_dir . "/lib/" . l:dll)
  else
    call system("cd " . a:install_dir . " && make")
  endif
endfunction


" ===================
" BundleMan Internals
" ===================

let s:WORKDIR = "."
let s:SCRIPT_PATH = resolve(expand('<sfile>:p'))

let s:PATHOGEN_URL = "https://github.com/tpope/vim-pathogen"
let s:UNZIP_SCRIPT_FILENAME = "BundleManUnzip.vbs"
let s:DOWNLOAD_SCRIPT_FILENAME = "BundleManDownload.vbs"
let s:TIMESTAMP_FILENAME = "BundleMan_timestamp.txt"

if has('win32') || has('win64')
  let s:MOVE_CMD_TEMPLATE = "robocopy {FROMDIR} {TODIR} /e /move"
  let s:DELDIR_CMD_TEMPLATE = "rmdir {DIR} /s /q"
  let s:DOWNLOAD_CMD_TEMPLATE = "cscript {WORKDIR}\\" . s:DOWNLOAD_SCRIPT_FILENAME . " //B {URL} {OUTFILE}"
  let s:UNZIP_CMD_TEMPLATE = "cscript {WORKDIR}\\" . s:UNZIP_SCRIPT_FILENAME . " //B {ZIPFILE} {DESTDIR}"
  let s:COMMITS_QUERY_CMD_TEMPLATE = "cscript {WORKDIR}\\" . s:DOWNLOAD_SCRIPT_FILENAME . " //B {URL} {WORKDIR}\\BundleMan_query.tmp & type {WORKDIR}\\BundleMan_query.tmp"
else
  let s:MOVE_CMD_TEMPLATE = "mv {FROMDIR}/* {TODIR}"
  let s:DELDIR_CMD_TEMPLATE = "rm -r {DIR}"
  if executable("curl")
    let s:DOWNLOAD_CMD_TEMPLATE = "curl -L -k -o {OUTFILE} {URL}"
  else
    let s:DOWNLOAD_CMD_TEMPLATE = "wget --no-check-certificate -O {OUTFILE} {URL}"
  endif
  let s:UNZIP_CMD_TEMPLATE = "tar xf {ZIPFILE} -C {DESTDIR}"
  let s:COMMITS_QUERY_CMD_TEMPLATE = "curl -L -k {URL}"
endif

" This will hold the bundle list
let s:bundles = []

" This will hold the ignored bundles list
let s:ignored_bundles = []

" Bundle commands for nicer bundle list configuration
function s:AddBundle(bundle)
  let bundle = a:bundle
  for key in ["url", "branch", "pre_install", "post_install", "install_only_subdir", "dir"]
    let bundle = substitute(bundle, key . ':', '"' . key . '":', '')
  endfor
  execute 'call add(s:bundles, ' . bundle . ')'
endfunction
function s:IgnoreBundle(bundle)
  let bundle = a:bundle
  if stridx(bundle, "url:") != -1
    let bundle = substitute(bundle, 'url:', '"url":', '')
  else
    let bundle = substitute(bundle, '{', '{ "url":', '')
  endif
  execute 'call add(s:ignored_bundles, ' . bundle . ')'
endfunction
function s:AddIgnoreBundle(bundle)
  let call_stack = expand("<sfile>")
  if stridx(call_stack, "BundleList") != -1
    call s:AddBundle(a:bundle)
  else
    call s:IgnoreBundle(a:bundle)
  endif
endfunction
command -nargs=1 Bundle call s:AddIgnoreBundle(<f-args>)

function s:IsWindows()
  return has('win32') || has('win64')
endfunction

function s:CreateDir(dir)
  let result = 0
  if !isdirectory(a:dir)
    call mkdir(a:dir)
  endif
  if isdirectory(a:dir)
    let result = 1
  endif
  return result
endfunction

function s:DeleteDir(dir)
  let dir = a:dir
  if s:IsWindows()
    let dir = substitute(dir, '/', '\', 'g')
  endif
  " NOTE: substitute does escaping in sub string also, so I need to do this in order to
  "       get two backslashes in variable in order to then get a backslash in command
  let dir = substitute(dir, '\\', '\\\\', 'g')
  let deldir_cmd = substitute(s:DELDIR_CMD_TEMPLATE, "{DIR}", dir, '')
  call system(deldir_cmd)
endfunction

function s:GetCurrentTimeStamp()
  if s:IsWindows()
    let tzinfo = system("systeminfo | find \"Time Zone\"")
    let timezone = matchstr(tzinfo, 'UTC[+-\d]\+:')[3:-1]
  else
    let timezone = strftime("%z")[:2]
  endif
  let time = localtime() - (timezone * 60 * 60)
  let timestamp = strftime("%Y-%m-%dT%XZ", time)
  return timestamp
endfunction

function s:DownloadFile(url, outfile)
  let download_cmd = substitute(s:DOWNLOAD_CMD_TEMPLATE, "{URL}", a:url, '')
  let download_cmd = substitute(download_cmd, "{OUTFILE}", a:outfile, '')
  let download_cmd = substitute(download_cmd, "{WORKDIR}", s:WORKDIR, '')
  call system(download_cmd)
endfunction

function s:GetRepoName(url)
  return remove(split(a:url, '/'), -1)
endfunction

function s:GetInstallDir(bundle)
  let repo_name = s:GetRepoName(a:bundle['url'])
  let install_dir = s:WORKDIR . "/bundle"
  if has_key(a:bundle, 'dir')
    let install_dir = install_dir . "/" . a:bundle['dir']
  else
    let install_dir = install_dir . "/" . repo_name
  endif
  return install_dir
endfunction

function s:IsBundleInstalled(bundle)
  let installed = 0
  let install_dir = s:GetInstallDir(a:bundle)
  if isdirectory(install_dir)
    if glob(install_dir . '/*') != ''
      let installed = 1
    endif
  endif
  return installed
endfunction

function s:IsBundleOutdated(bundle)
  let outdated = 1
  let timestamp_file = s:WORKDIR . '/' . s:TIMESTAMP_FILENAME
  if filereadable(timestamp_file)
    let lines = readfile(timestamp_file)
    if len(lines)
      let query_url = "https://api.github.com/repos" . split(a:bundle['url'], "github.com")[1] . '/commits?since=' . lines[0]
      let commit_query_cmd = substitute(s:COMMITS_QUERY_CMD_TEMPLATE, "{URL}", query_url, '')
      let commit_query_cmd = substitute(commit_query_cmd, "{WORKDIR}", s:WORKDIR, 'g')
      let repo_commits = system(commit_query_cmd)
      if repo_commits !~ "commit"
        let outdated = 0
      endif
    endif
  endif
  return outdated
endfunction

function s:InstallRepo(url, branch, destdir, install_only_subdir)
  let repo_name = s:GetRepoName(a:url)
  let outdir = s:WORKDIR . "/BundleMan_temp_zipfile_dir"
  if s:IsWindows()
    let zipurl = a:url . "/archive/" . a:branch . "/master.zip"
    let outfile = s:WORKDIR . "/BundleMan_temp_zipfile.zip"
  else
    let zipurl = a:url . "/archive/" . a:branch . "/master.tar.gz"
    let outfile = s:WORKDIR . "/BundleMan_temp_zipfile.tar.gz"
    " Unzip command in Linux does not create the destination directory
    call s:CreateDir(outdir)
  endif
  " download zip
  let download_cmd = substitute(s:DOWNLOAD_CMD_TEMPLATE, "{URL}", zipurl, '')
  let download_cmd = substitute(download_cmd, "{OUTFILE}", outfile, '')
  let download_cmd = substitute(download_cmd, "{WORKDIR}", s:WORKDIR, '')
  call system(download_cmd)
  " unzip to temp dir
  let unzip_cmd = substitute(s:UNZIP_CMD_TEMPLATE, "{ZIPFILE}", outfile, '')
  let unzip_cmd = substitute(unzip_cmd, "{DESTDIR}", outdir, '')
  let unzip_cmd = substitute(unzip_cmd, "{WORKDIR}", s:WORKDIR, '')
  call system(unzip_cmd)
  " move contents to destdir
  let fromdir = outdir . "/" . repo_name . "-" . a:branch
  if a:install_only_subdir != ''
    let fromdir = fromdir . "/" . a:install_only_subdir
  endif
  call s:CreateDir(a:destdir)
  let move_cmd = substitute(s:MOVE_CMD_TEMPLATE, "{FROMDIR}", fromdir, '')
  let move_cmd = substitute(move_cmd, "{TODIR}", a:destdir, '')
  call system(move_cmd)
  " clean
  call delete(outfile)
  call s:DeleteDir(outdir)
endfunction

" NOTE: Replaced with BundleMan_rtp.vim
" function s:InstallPathogen(vimfiles)
"   call s:InstallRepo(s:PATHOGEN_URL, 'master', a:vimfiles, '')
"   call s:CreateDir(a:vimfiles . "/bundle")
" endfunction

function s:UpdateBundles(vimfiles)
  " Set vimfiles as workdir (it must be writable)
  let s:WORKDIR = a:vimfiles
  " Get timestamp to save after update is done
  let timestamp = s:GetCurrentTimeStamp()
  " Unpack scripts used to install repos
  call s:UnpackUnzipScript()
  call s:UnpackDownloadScript()
  " Install/Update Pathogen
  " NOTE: Replaced with BundleMan_rtp.vim
  " call s:InstallPathogen(a:vimfiles)
  " Create bundle directory
  call s:CreateDir(a:vimfiles . "/bundle")
  " Download and install repos
  let i = 0
  while i < len(s:bundles)
    let bundle = s:bundles[i]
    let is_installed = s:IsBundleInstalled(bundle)
    let is_outdated = s:IsBundleOutdated(bundle)
    if !is_installed || is_outdated
      let repo_name = s:GetRepoName(bundle['url'])
      let pre_install_ok = 1
      let pre_install = get(bundle, 'pre_install', '')
      if pre_install != ''
        echo "Executing pre install for " . repo_name
        execute 'let pre_install_ok = ' . pre_install . '()'
      endif
      if pre_install_ok
        if is_installed
          echo "Updating " . repo_name
          call s:CleanBundle(bundle)
        else
          echo "Installing " . repo_name
        endif
        let bundle['install_dir'] = s:GetInstallDir(bundle)
        call s:InstallRepo(bundle['url'], get(bundle, 'branch', 'master'), bundle['install_dir'], get(bundle, 'install_only_subdir', ''))
        let bundle['updated'] = 1
      else
        echo "Pre install failed. Canceling install/update of " . repo_name
      endif
    endif
    let i += 1
  endwhile
  " Execute post install actions
  let i -= 1
  while i >= 0
    let bundle = s:bundles[i]
    let updated = get(bundle, 'updated')
    let post_install = get(bundle, 'post_install', '')
    if updated && (post_install != '')
      let repo_name = s:GetRepoName(bundle['url'])
      echo "Executing post install for " . repo_name
      execute 'call ' . post_install . '("' . bundle['install_dir'] . '")'
    endif
    let i -= 1
  endwhile
  " Save timestamp
  call writefile([timestamp], a:vimfiles . '/' . s:TIMESTAMP_FILENAME)
  " Clean
  call s:EraseUnzipScript()
  call s:EraseDownloadScript()
endfunction

function s:CleanBundle(bundle)
  let repo_name = s:GetRepoName(a:bundle['url'])
  let install_dir = s:GetInstallDir(a:bundle)
  call s:DeleteDir(install_dir)
endfunction

function s:CleanBundles(vimfiles)
  " Set vimfiles as workdir (it must be writable)
  let s:WORKDIR = a:vimfiles
  let i = 0
  while i < len(s:bundles)
    let bundle = s:bundles[i]
    let repo_name = s:GetRepoName(bundle['url'])
    echo "Uninstalling " . repo_name
    call s:CleanBundle(bundle)
    let i += 1
  endwhile
endfunction

function s:CleanNotOwned(vimfiles)
  " Set vimfiles as workdir (it must be writable)
  let s:WORKDIR = a:vimfiles
  let owned_dirs = {}
  " Grab owned bundle dirs
  let i = 0
  while i < len(s:bundles)
    let bundle = s:bundles[i]
    let owned_dirs[s:GetInstallDir(bundle)] = 1
    let i += 1
  endwhile
  " Add ignored dirs (that should not be touched)
  let i = 0
  while i < len(s:ignored_bundles)
    let bundle = s:ignored_bundles[i]
    let owned_dirs[s:GetInstallDir(bundle)] = 1
    let i += 1
  endwhile
  " Go dir by dir and erase those we not own or must ignore
  let bundle_dirs = glob(a:vimfiles . "/bundle/*", 0, 1)
  let i = 0
  while i < len(bundle_dirs)
    let bundle_dir = bundle_dirs[i]
    if s:IsWindows()
      let bundle_dir = substitute(bundle_dir, '\', '/', 'g')
    endif
    if isdirectory(bundle_dir) && !get(owned_dirs, bundle_dir)
      let repo_name = s:GetRepoName(bundle_dir)
      echo "Uninstalling " . repo_name
      call s:DeleteDir(bundle_dir)
    endif
    let i += 1
  endwhile
endfunction

let s:UNZIP_SCRIPT  = "set fso = CreateObject(\"Scripting.FileSystemObject\")\r"
let s:UNZIP_SCRIPT .= "pathToZipFile=fso.GetAbsolutePathName(Wscript.Arguments(0))\r"
let s:UNZIP_SCRIPT .= "extractTo=fso.GetAbsolutePathName(Wscript.Arguments(1))\r"
let s:UNZIP_SCRIPT .= "if not fso.FolderExists(extractTo) then\r"
let s:UNZIP_SCRIPT .= "    fso.CreateFolder(extractTo)\r"
let s:UNZIP_SCRIPT .= "end if\r"
let s:UNZIP_SCRIPT .= "set sa = CreateObject(\"Shell.Application\")\r"
let s:UNZIP_SCRIPT .= "set filesInzip=sa.NameSpace(pathToZipFile).items\r"
let s:UNZIP_SCRIPT .= "sa.NameSpace(extractTo).CopyHere filesInzip, 20\r"

function s:UnpackUnzipScript()
  call writefile([s:UNZIP_SCRIPT], s:WORKDIR . '/' . s:UNZIP_SCRIPT_FILENAME)
endfunction

function s:EraseUnzipScript()
  call delete(s:WORKDIR . '/' . s:UNZIP_SCRIPT_FILENAME)
endfunction

let s:DOWNLOAD_SCRIPT  = "URL = WScript.Arguments(0)\r"
let s:DOWNLOAD_SCRIPT .= "saveTo = WScript.Arguments(1)\r"
let s:DOWNLOAD_SCRIPT .= "Set objXMLHTTP = CreateObject(\"MSXML2.ServerXMLHTTP\")\r"
let s:DOWNLOAD_SCRIPT .= "objXMLHTTP.open \"GET\", URL, false\r"
let s:DOWNLOAD_SCRIPT .= "objXMLHTTP.send()\r"
let s:DOWNLOAD_SCRIPT .= "If objXMLHTTP.Status = 200 Then\r"
let s:DOWNLOAD_SCRIPT .= "    Set objADOStream = CreateObject(\"ADODB.Stream\")\r"
let s:DOWNLOAD_SCRIPT .= "    objADOStream.Open\r"
let s:DOWNLOAD_SCRIPT .= "    objADOStream.Type = 1 'adTypeBinary\r"
let s:DOWNLOAD_SCRIPT .= "    objADOStream.Write objXMLHTTP.ResponseBody\r"
let s:DOWNLOAD_SCRIPT .= "    objADOStream.Position = 0    'Set the stream position to the start\r"
let s:DOWNLOAD_SCRIPT .= "    Set objFSO = Createobject(\"Scripting.FileSystemObject\")\r"
let s:DOWNLOAD_SCRIPT .= "    If objFSO.Fileexists(saveTo) Then objFSO.DeleteFile saveTo\r"
let s:DOWNLOAD_SCRIPT .= "    Set objFSO = Nothing\r"
let s:DOWNLOAD_SCRIPT .= "    objADOStream.SaveToFile saveTo\r"
let s:DOWNLOAD_SCRIPT .= "    objADOStream.Close\r"
let s:DOWNLOAD_SCRIPT .= "    Set objADOStream = Nothing\r"
let s:DOWNLOAD_SCRIPT .= "End if\r"
let s:DOWNLOAD_SCRIPT .= "Set objXMLHTTP = Nothing\r"

function s:UnpackDownloadScript()
  call writefile([s:DOWNLOAD_SCRIPT], s:WORKDIR . '/' . s:DOWNLOAD_SCRIPT_FILENAME)
endfunction

function s:EraseDownloadScript()
  call delete(s:WORKDIR . '/' . s:DOWNLOAD_SCRIPT_FILENAME)
endfunction

function s:UpdateRTP(vimfiles)
  let l:vimfiles = substitute(a:vimfiles, '\\', '/', 'g')
  let l:lines = [
        \ 'let s:bundles = fnamemodify(resolve(expand("<sfile>:p")), ":h") . "/bundle"',
        \ 'let s:bundles = substitute(s:bundles, "\\", "/", "g")',
        \ 'let s:paths = "$HOME/.vim,$VIM/vimfiles,$VIMRUNTIME"'
        \]
  let l:afterlines = ['let s:paths .= ",$VIM/vimfiles/after,$HOME/.vim/after"']
  let l:set_rtp = ['exec "set rtp=" . s:paths']
  for l:bundle_path in glob(l:vimfiles . '/bundle/*', 0, 1)
    let l:bundle = fnamemodify(l:bundle_path, ':t')
    call add(l:lines, 'let s:paths .= "," . s:bundles . "/' . l:bundle . '"')
    if isdirectory(l:bundle_path . '/after')
      call add(l:afterlines, 'let s:paths .= "," . s:bundles . "/' . l:bundle . '/after"')
    endif
  endfor
  call writefile(l:lines + l:afterlines + l:set_rtp, l:vimfiles . '/BundleMan_rtp.vim')
endfunction

function s:GetVimfiles()
  if g:VIMFILES == 'HOME'
    if s:IsWindows()
      let vimfiles = $HOME . '/' . "vimfiles"
    else
      let vimfiles = $HOME . '/' . ".vim"
    endif
  elseif g:VIMFILES == 'VIM'
    let vimfiles = $VIM . '/' . "vimfiles"
  elseif stridx(g:VIMFILES, '/') == 0
    let vimfiles = g:VIMFILES
  elseif g:VIMFILES == '.'
    let vimfiles = fnamemodify(s:SCRIPT_PATH, ':h')
  else
    let vimfiles = fnamemodify(s:SCRIPT_PATH, ':h') . '/' . g:VIMFILES
  endif
  " Convert to forward slashes and remove trailing slash if any
  let vimfiles = substitute(vimfiles, '\', '/', 'g')
  let vimfiles = substitute(vimfiles, '/$', '', '')
  return vimfiles
endfunction

function s:Main()
  " redraw
  let vimfiles = s:GetVimfiles()
  if !s:CreateDir(vimfiles)
    echo "Chosen vimfiles directory does not exist and could not be created!"
    return
  endif
  if argc() > 0
    let action = argv(0)
  else
    let action = ""
  endif
  if action == "update"
    echo "Updating bundles..."
    call s:UpdateBundles(vimfiles)
    if g:TAKE_OWNERSHIP
      call s:CleanNotOwned(vimfiles)
    endif
  elseif action == "clean"
    echo "Erasing all bundles..."
    call s:CleanBundles(vimfiles)
  elseif action == "reinstall"
    echo "Re-Installing all bundles..."
    call s:CleanBundles(vimfiles)
    call s:UpdateBundles(vimfiles)
  else
    " Default action is update
    echo "Updating bundles..."
    call s:UpdateBundles(vimfiles)
    if g:TAKE_OWNERSHIP
      call s:CleanNotOwned(vimfiles)
    endif
  endif
  call s:UpdateRTP(vimfiles)
  echo "Done!"
endfunction

" Load bundle list and start proceedings
call BundleList()
call IgnoreList()
call s:Main()
echo "Press any key to exit..."
call getchar()
qa!
