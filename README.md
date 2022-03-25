# smartpairs.vim

Smartpairs.vim will add proper pairings as you type:

    You type        You get        Notes
    (               (_)            "_" represents the cursor
    <BS>            _
    [               [_]
    ]               []_
    <BS>            [_
    <BS>            _
    {               {_}
    <CR>            {              Cursor will be indented using current syntax
                      _
                    }

It has multiple options you can use to configure it. See the
[documentation](doc/smartpairs.txt) for all the details.

# Installation

With [vim-plug](https://github.com/junegunn/vim-plug):

    Plug 'gosukiwi/vim-smartpairs'

Vim 8+ package manager

    git clone https://github.com/gosukiwi/vim-smartpairs.git \
                ~/.vim/pack/{whatever name you want}/start/vim-smartpairs

See `:help package` for more info.

# Why

There are other plugins which do pairings as well, but in my opinion they do
too much. Because they do so much, there are lots of edge cases where you
don't want the pairing functionality to trigger, but it does anyways, and it
ends up getting in the way.

This plugin aims to be minimal, and try to be as unobtrusive and unsurprising
as possible.
