
" Installation: copy to .vim/plugins folder, set the p4pr.pl path correctly
" p4pr.pl can be obtained from http://public.perforce.com/guest/fredric_fredricson/P4DB/rel/2.1/p4pr.perl

" Would not be possible without Jony Wareing's SvnBlame [ https://github.com/Jonty/svnblame.vim.git ]
" author: Sri Doddapanei. github@ealize.com

let p4pr = '/service/bin/p4hist'

if !filereadable(p4pr)
    finish
endif

if exists("loadedp4Blame")
    finish
endif

let loadedp4Blame = 1

function P4Blame()
    let thisFile = expand("%")

    let filePath = system('dirname ' . thisFile)
    let filePath = substitute(filePath, "\n", "", "g")

    let filestatus = system('p4 fstat ' . thisFile . ' | grep -wo  "headRev"')
    if filestatus <# "headRev"
       echohl WarningMsg | echon thisFile . "Cannot Blame:  Not under perforce"
       return
    endif

    echo "Preparing to Blame: '" . thisFile . "'..."

    " Save this window state, bind scroll vertically to children, turn off wrapping
    let parentView = winsaveview()
    set scrollbind
    set scrollopt=ver
    set nowrap

    " Blame baby blame
    let blameSrc = system(g:p4pr . ' ' . thisFile . ' | sed -r -e "s/( *[0-9]+) +([a-zA-Z0-9]+).*/ \1  \2 /"')
    let blameLines = split(blameSrc, "\n")
    let i = 0
    let blameOutput = ""
    while i < len(blameLines)
        let line = blameLines[i]
        let lineLen = strlen(line)
        if lineLen > 0
            let blameOutput .= line . "\n"
        endif
        let i = i + 1
    endwhile

    let blameWidth = 30
    " Create a new buffer, dump output and nuke the blank line inserted on creation
    0vnew
    put =blameOutput
    1d
    execute "vertical resize " . blameWidth

    " Make the child a non-wrapping scratch buffer
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted
    setlocal nonumber

    " Sync the child to the same vert position in the file as the parent
    let childView = winsaveview()
    let childView.lnum = parentView.lnum
    let childView.topline = parentView.topline
    call winrestview(childView)

    " Locally rebind the trigger to close the child
    nnoremap <buffer> <silent> <C-b> :call EndP4Blame()<CR>
    " And also close the child if we move to another buffer 
    " (prevents having more than one blame open)
    augroup blame
        autocmd BufLeave * call EndP4Blame()
    augroup end

    " This gets rid of the dreaded 'Press ENTER or type command to continue'
    " message you get after echoing
    redraw
endf

function EndP4Blame()
    execute ":close"
    autocmd! blame
endf

map <C-b> :call P4Blame()<CR>
