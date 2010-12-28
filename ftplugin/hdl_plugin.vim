"------------------------------------------------------------------------------
" Created by         : Vorx Ltd.com
" Filename           : hdl_plugin.vim
" Author             : ChenYong
" Created On         : 2010-11-02 13:17
" Last Modified      : 2010-12-08 14:07
" Description        : vhdl/verilog plugin
" Version            : v2.0
"
" history            :  v1.0    创建插件，实现编译，加入注释，文件头等功能 
"                       v1.1    加入函数Component_Build() 可以实现垂直分割窗口
"                               生成component信息
"                       v1.2    加入函数Tb_Build() 可以为vhdl模块生成testbench文档
"                       v1.3    1 生成进程的命令改为：ProBuild
"                               2 加入函数Tb_Vhdl_Build(type) 函数
"                                   代替函数Tb_Build() 
"                                   修改了testbench文档的生成方式
"                                   功能：可以生成vhdl模块的vhdl testbench或者 verilog testbench
"                               3 修改了Component_Build()函数
"                                   修改了component的生成方式
"                               4 代码风格做了一些修改
"                               5 修改了光标位置
"                       v1.4    修改了Tb_Vhdl_Build(type)函数 使生成的component按原信号顺序排列
"                       v1.5    加入菜单
"                       v1.6    优化程序
"                       v1.7    Component_Build可以用变量定义选择instant窗口的方式
"                               不定义 g:RightB_Commponent  则水平分割打开
"                               g:RightB_Commponent = 1 原文件右侧垂直打开
"                               g:RightB_Commponent = 0 原文件左侧垂直打开
"                       v1.8    修改了一些错误
"                       v1.9    1 修改了AddFileInformation()和AddContent()函数
"                               2 加入变量g:HDL_Author g:HDL_Company g:Verilog_Timescale
"                                 可以在vimrc中添加设置,例如:
"                                   let g:HDL_Company = "Vorx"
"                                   let g:HDL_Author = "ChenYong"
"                                   let g:Verilog_Timescale = " 1ns / 1ns"
"                               3 加入generic部分 使可识别generic
"                               4 加入g:HDL_Clock_Period 时钟周期可设置，默认为64
"                                   let g:HDL_Clock_Period = 64
"                               5 暂时不支持一行多个port
"                               6 菜单中加入compile file 默认快捷键为<F7>
"                               7 菜单中加入vlib work 默认快捷键为<F6>
"                                   需要安装modelsim。windows下需设置环境变量PATH=$ModelSim\win32
"                       v2.0    现在可以支持同一行多个port了
"                               
"                               
"
"
"
"                                   
"
"                      
"------------------------------------------------------------------------------
if exists('b:hdl_plugin') || &cp || version < 700
    finish
endif
let b:hdl_plugin = 1

nmenu HDL.Create\ a\ Library<Tab>F6             <Esc>:!vlib work<CR><CR>
nmenu HDL.Compile\ File<Tab>F7                  :ModSimComp<CR><CR>
nmenu HDL.Add\ File\ Header<Tab>:AddInfo        :AddInfo<CR>
nmenu HDL.Add\ Content<Tab>:Acontent            :Acontent<CR>
nmenu HDL.Process\ Build<Tab>:ProBuild          :ProBuild<CR>
nmenu HDL.Vhdl\ Entity\ Build<Tab>:VhdlEntity   :VhdlEntity<CR>
nmenu HDL.Vhdl\ Component\ Build<Tab>:CompoB    :CompoB<CR> 
nmenu HDL.Verilog\ Instant\ for\ VHDL<Tab>:InstantV     :InstantV<CR>
nmenu HDL.Vhdl\ Testbench\ for\ VHDL<Tab>:TbVHDVhdl     :TbVHDVhdl<CR>
nmenu HDL.Verilog\ Testbench\ for\ VHDL<Tab>:TbVHDVerilog    :TbVHDVerilog<CR>

command     AddInfo     :call AddFileInformation()
command     Acontent    :call AddContent()
command     ProBuild    :call Always_Process_Build("posedge", "posedge")
command     VhdlEntity  :call Module_Entity_Build()
command     ModSimComp  :call Model_Sim_Compile()
command     CompoB      :call Component_Build("vhdl")
command     InstantV    :call Component_Build("verilog")
command     TbVHDVhdl   :call Tb_Vhdl_Build("vhdl")
command     TbVHDVerilog    :call Tb_Vhdl_Build("verilog")

nmap <silent><F7> :ModSimComp<CR><CR>
nmap <silent><F6> <Esc>:!vlib work<CR><CR>

if !exists("g:Width_of_Component")
    let g:Width_of_Component = "70"
endif

if !exists("g:Height_of_Component")
    let g:Height_of_Component = "25"
endif

if !exists("g:HDL_Author")
    let g:HDL_Author = "ChenYong"
endif

if !exists("g:HDL_Company")
    let g:HDL_Company = ""
endif

if !exists("g:Verilog_Timescale")
    let g:Verilog_Timescale = "1ns / 1ps"
endif

if !exists("g:HDL_Clock_Period")
    let g:HDL_Clock_Period = 64
endif

"------------------------------------------------------------------------------
"Function    : Model_Sim_Compile() 
"Description : Compile with ModelSim  
"------------------------------------------------------------------------------
function Model_Sim_Compile()
    if Check_File_Type() == 1
        set makeprg=vcom\ -work\ work\ %
        execute "make"
        execute "cw"
    elseif Check_File_Type() == 2 
        set makeprg=vlog\ -work\ work\ %
        execute "make"
        execute "cw"
    else
        echohl ErrorMsg
        echo "This filetype can't be compiled by modelsim vcom/vlog!"
        echohl None 
    endif
endfunction

"set error format 
set errorformat=\*\*\ %tRROR:\ %f(%l):\ %m,\*\*\ %tRROR:\ %m,\*\*\ %tARNING:\ %m,\*\*\ %tOTE:\ %m,%tRROR:\ %f(%l):\ %m,%tARNING\[%*[0-9]\]:\ %f(%l):\ %m,%tRROR:\ %m,%tARNING\[%*[0-9]\]:\ %m

"------------------------------------------------------------------------
"Function    : AddFileInformation() 
"Decription  : Add File Header 
"------------------------------------------------------------------------
function AddFileInformation()
    if Check_File_Type() == 1
        let comment = "--"
        let others = "library ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.std_logic_arith.all;\n"
                    \."use ieee.std_logic_unsigned.all;\n\n"
    elseif Check_File_Type() == 2 
        let comment = "//"
        let others = "`timescale ".g:Verilog_Timescale."\n\n"
    elseif Check_File_Type() == 3 
        let comment = "\""
        let others = ""
"if you want add other file type ,then add in here 
"    elseif file_type_temp == ""
"        let comment = ""
"        let others = ""
    else 
        let comment = ""
        let others = ""
    endif
    let header = comment."-------------------------------------------------------------------------------\n"
                \.comment." Created by\t\t: ".g:HDL_Company."\n".comment." Filename\t\t\t: ".expand("%")."\n"
                \.comment." Author\t\t\t: ".g:HDL_Author."\n".comment." Created On\t\t: "
                \.strftime("%Y-%m-%d %H:%M")."\n".comment." Last Modified\t: \n".comment
                \." Version\t\t\t: v1.0\n".comment." Description\t\t: \n".comment."\t\t\t\t\t\t\n".comment
                \."\t\t\t\t\t\t\n".comment
                \."-------------------------------------------------------------------------------\n\n"
                \.others
    exe "ks"
    exe "normal gg"
    silent put! =header
    exe "'s"
endfunction

"------------------------------------------------------------------------------
"Function  : AddContent() 
"Description: 在光标当前位置插入注释
"------------------------------------------------------------------------------
function AddContent()
    let file_type_temp = expand("%:e")
"    let file_type_temp = getftype(expand("%:p"))
    if Check_File_Type() == 1
        let comment = "--"
    elseif Check_File_Type() == 2 
        let comment = "//"
    elseif Check_File_Type() == 3 
        let comment = "\""
"if you want add other file type ,then add in here 
"    elseif Check_File_Type() == 
"        let comment = ""
    else 
        let comment = ""
    endif
    let content = comment."-------------------------------------------------------------------------------\n"
                \.comment." Function\t\t:\t\n".comment." Description\t:\t\n"
                \.comment."-------------------------------------------------------------------------------\n"
    silent put =content
    call search("Function",'b')
    exe "normal $"
endfunction

"---------------------------------------------------------------
"        Verilog中插入always
"        VHDL中插入process
"        Add an always or process statement
"        you must add comment after signal declare 
"        such as:
"        verilog:
"        input  clk; //clock
"        input  rst; //reset 
"        or:
"        reg    clk; //clock
"        reg    rst; //reset
"        vhdl:
"        port(
"        clk    :   std_logic;      --clock
"        rst    :   std_logic       --reset 
"        )
"        or: 
"        signal     clk     :   std_logic;  --clock
"        signal     rst     :   std_logic;  --reset
"---------------------------------------------------------------
function Always_Process_Build(clk_edge, rst_edge)
    let file_type_temp = expand("%:e")
    if file_type_temp == "verilog"
       for line in getline(1, line("$"))
           if line =~ '^\s*//.*$'
               continue
           elseif line =~ '^\s*\<input\>.*//\s*\<clock\>\s*$'
              let line = substitute(line, '^\s*\<input\>\s*', "", "")
              let clk  = substitute(line, '\s*;.*$', "", "")
           elseif line =~ '^\s*\<input\>.*//\s*\<reset\>\s*$'
              let line = substitute(line, '^\s*\<input\>\s*', "", "")
              let rst  = substitute(line, '\s*;.*$', "", "")
           elseif line =~ '^\s*\<reg\>.*//\s*\<clock\>\s*$'
              let line = substitute(line, '^\s*\<reg\>\s*', "", "")
              let clk  = substitute(line, '\s*;.*$', "", "")
           elseif line =~ '^\s*\<reg\>.*//\s*\<reset\>\s*$'
              let line = substitute(line, '^\s*\<reg\>\s*', "", "")
              let rst  = substitute(line, '\s*;.*$', "", "")
           endif
       endfor

       if !exists('clk')
           let clk = "clk"
       endif

       if !exists('rst')
           let rst = "rst"
       endif

       let curr_line = line(".")
       if a:clk_edge == "posedge" && a:rst_edge == "posedge"
          call append(curr_line,   "always @(posedge ".clk." or posedge ".rst.") begin ")
          call append(curr_line+1, "  if (".rst.") begin")
          call append(curr_line+2, "  end")
          call append(curr_line+3, "  else begin")
          call append(curr_line+4, "  end")
          call append(curr_line+5, "end")
       elseif a:clk_edge == "negedge" && a:rst_edge == "posedge"
          call append(curr_line,   "always @(negedge ".clk." or posedge ".rst.") begin ")
          call append(curr_line+1, "  if (".rst.") begin")
          call append(curr_line+2, "  end")
          call append(curr_line+3, "  else begin")
          call append(curr_line+4, "  end")
          call append(curr_line+5, "end")
       elseif a:clk_edge == "posedge" && a:rst_edge == "negedge"
          call append(curr_line,   "always @(posedge ".clk." or negedge ".rst.") begin ")
          call append(curr_line+1, "  if (!".rst.") begin")
          call append(curr_line+2, "  end")
          call append(curr_line+3, "  else begin")
          call append(curr_line+4, "  end")
          call append(curr_line+5, "end")
       elseif a:clk_edge == "negedge" && a:rst_edge == "negedge"
          call append(curr_line,   "always @(negedge ".clk." or negedge ".rst.") begin ")
          call append(curr_line+1, "  if (!".rst.") begin")
          call append(curr_line+2, "  end")
          call append(curr_line+3, "  else begin")
          call append(curr_line+4, "  end")
          call append(curr_line+5, "end")
       elseif a:clk_edge == "posedge" && a:rst_edge == ""
          call append(curr_line,   "always @(posedge ".clk.") begin ")
          call append(curr_line+1, "end")
       elseif a:clk_edge == "negedge" && a:rst_edge == ""
          call append(curr_line,   "always @(negedge ".clk.") begin ")
          call append(curr_line+1, "end")
       else
          call append(curr_line,   "always @(*) begin")
          call append(curr_line+1, "end")
       endif
   elseif file_type_temp == "vhd"
       for line in getline(1, line("$"))
           if line =~ '^\s*--.*$'
              continue 
           else
               if line =~ '^.*\<in\>.*\<std_logic\>.*\<clock\>.*$'
                   let line = substitute(line,'\s*:.*$',"","")
                   let clk  = substitute(line,'^\s*',"","")
               elseif line =~ '^.*\<in\>.*\<std_logic\>.*\<reset\>.*$'
                   let line = substitute(line,'\s*:.*$',"","")
                   let rst  = substitute(line,'^\s*',"","")
               elseif line =~ '^.*\<signal\>.*\<std_logic\>.*\<clock\>.*$'
                   let line = substitute(line,'\s*:.*$',"","")
                   let clk  = substitute(line,'^.*\<signal\>\s*',"","")
               elseif line =~ '^.*\<signal\>.*\<std_logic\>.*\<reset\>.*$'
                   let line = substitute(line,'\s*:.*$',"","")
                   let rst  = substitute(line,'^.*\<signal\>\s*',"","")
               endif
           endif
       endfor

       if !exists('clk')
           echohl ErrorMsg
           echo     "Clock Set is Wrong...."
           echohl None
           return
       endif

       if !exists('rst')
           echohl ErrorMsg
           echo     "Reset Set is Wrong...."
           echohl None
           return
       endif

       let curr_line = line('.')
       call append(curr_line,"process(".clk.",".rst.") ") 
       call append(curr_line+1,"begin ")
       call append(curr_line+2,"    if ".rst."='1' then ")
       call append(curr_line+3,"    elsif rising_edge(".clk.") then")
       call append(curr_line+4,"    end if; ")
       call append(curr_line+5,"end process; ")


   else
       echohl ErrorMsg
       echo "Wrong filetype!"
       echohl None 
   endif 
endfunction

"------------------------------------------------------------------------------
"Function    : Module_Entity_Build() 
"Description : 在当前位置插入entity
"------------------------------------------------------------------------------
function Module_Entity_Build()
    let file_type_temp = expand("%:e")
    let ent_name = inputdialog("entity name:")
    if ent_name != ""
        if file_type_temp == "vhd"
            let all_part = "entity ".ent_name." is\n\tport (\n\n\t);\nend ".ent_name.";\n\narchitecture arc of "
                        \.ent_name." is\n\n\nbegin\n\nend arc;"
        elseif file_type_temp == "v"
            let all_part = "module ".ent_name."\n(\n\n);\n\nendmodule"
        else 
            echohl ErrorMsg
            echo "Wrong filetype!"
            echohl None 
        endif
        silent put! =all_part
        call search('\<port\>\s*(','b')
    endif
endfunction 

"------------------------------------------------------------------------
"Function    : Get_Information_Of_Entity() 
"Decription  : get position and port map of the entity 
"------------------------------------------------------------------------
function Get_Information_Of_Entity()
    " 保存初始位置，entity读取完成跳转回来
    exe "ks"
    " Get the entity position
    let first_line = search('\<entity\>.*\<is\>','w')
    if first_line == 0
        echo "Can't Find Start Entity."
        return 0
    endif
    let last_line = searchpair('\<entity\>.*\<is\>','','\<end\>.*;','W')
    if last_line == 0
        echo "Can't Find End Entity."
        return 0
    endif
    " entity name 
    let line = getline(first_line)
    let s:ent_name = substitute(line,'^\s*\<entity\>\s*',"","")
    let s:ent_name = substitute(s:ent_name,'\s*\<is\>.*$',"","")
    " 端口的首行和末行
    call cursor(first_line,1)
    let port_start_line = search('\<port\>','W',last_line)
    let i = 1
    while i
        if getline(line('.')) =~ '^\s*--'
            let port_start_line = search('\<port\>','W',last_line)
            let i = 1
        else
            let i = 0
        endif
    endwhile
    call search('(','W')
    exe "normal %"
    let port_last_line = line('.')
    " 检查generic的首行和末行
    call cursor(first_line,1)
    let s:generic_start_line = search('\<generic\>','W',last_line)
    if getline(line('.')) =~ '^\s*--' 
        let s:generic_start_line = search('\<generic\>','W',last_line)
    endif
    if s:generic_start_line != 0
        call search('(','W')
        exe "normal %"
        let generic_last_line = line('.')
        let s:generic_count = 0
        call Get_Generic_Port(s:generic_start_line,generic_last_line)
    endif
    " 设置3个List来存放端口的信息
    let s:port_cout = 0
    let s:port = []
    let s:type = []
    let s:direction = []
    let i = port_start_line
    while i <= port_last_line
        let line = getline(i)
        " 将行尾的;和最后一行的);去掉
        if i == port_last_line
            let line = substitute(line,'\s*)\s*;.*$',"","")
        else 
            let line = substitute(line,'\s*;.*$',"","")
        endif
        " 注释行跳过
        if line =~ '^\s*--.*$'
            let i = i + 1
            continue
        endif
        " port和signal在一行时删去port(
        if line =~ '^\s*\<port\>\s*(.*'
            let line = substitute(line,'^\s*\<port\>\s*(\s*',"","")
        endif
        " 行首的(删掉
        if line =~ '^\s*(.*$'
            let line = substitute(line,'^\s*(\s*',"","")
        endif
        " 行尾有注释 先删去
        if line =~ '^.*--.*$'
            let line = substitute(line,'--.*$',"","")
        endif
        " 删掉行首的空格
        let line = substitute(line,'^\s*',"","")
        " 将信号按顺序存在list列表中
        if line =~ '^.*:\s*\<in\>.*$' || line =~ '^.*:\s*\<out\>.*$'
            let port_t = substitute(line,'\s*:.*$',"","")
            if line =~ ':\s*\<in\>' 
                let direction_t = "in"
                let type_t = substitute(line,'^.*:\s*\<in\>\s*',"","")
            elseif line =~ ':\s*\<out\>'
                let direction_t = "out"
                let type_t = substitute(line,'^.*:\s*\<out\>\s*',"","")
            endif
            " 如果多个port在同一行
            if port_t =~ ','
                let port_t = substitute(port_t,'\s*',"","")
                let comma_pos = [-1]
                let j = 1
                while 1
                    let last_comma = stridx(port_t,",",comma_pos[j-1]+1)
                    call add(comma_pos,last_comma)
                    if comma_pos[j] == -1
                        break
                    endif
                    let j = j + 1
                endwhile  
                let k = 0
                while k < j 
                    if k == j - 1
                        call add(s:port,strpart(port_t,comma_pos[k]+1))
                    else
                        call add(s:port,strpart(port_t,comma_pos[k]+1,comma_pos[k+1]-comma_pos[k]-1))
                    endif
                    call add(s:direction,direction_t)
                    call add(s:type,type_t)
                    let s:port_cout = s:port_cout + 1
                    let k = k + 1
                endwhile
            else
                " 将端口信息存于List中
                call add(s:port,port_t)
                call add(s:direction,direction_t)
                call add(s:type,type_t)
                let s:port_cout = s:port_cout + 1
            endif
        else 
            let i = i + 1
            continue
        endif
        let i = i + 1
    endwhile

    " 跳转回刚刚标记的地方
    exe "'s"
    return 1
endfunction

"------------------------------------------------------------------------
"Function    : Get generic information from the file 
"Decription  :  
"------------------------------------------------------------------------
function Get_Generic_Port(start_line,last_line)
    " 设置3个List来存放端口的信息
    let s:generic_count = 0
    let s:generic_port = []
    let s:generic_type = []
    let s:generic_value = []
    let i = a:start_line
    while i <= a:last_line
        let line = getline(i)
        " 空格先删掉
        let line = substitute(line,'\s*',"","")
        " 注释行跳过
        if line =~ '^--.*$'
            let i = i + 1
            continue
        endif
        " 将最后的;和最后一行的);去掉
        if i == a:last_line
            let line = substitute(line,');.*$',"","")
        else 
            let line = substitute(line,';.*$',"","")
        endif
        " generic和port在一行时删去generic(
        if line =~ '^\<generic\>(.*'
            let line = substitute(line,'\<generic\>(',"","")
        endif
        " (和port在一行时删去(
        if line =~ '^(.*$'
            let line = substitute(line,'(',"","")
        endif
        " 行尾有注释 应先删去
        if line =~ '^.*--.*$'
            let line = substitute(line,'--.*$',"","")
        endif
        
        let pos_1 = stridx(line,":")
        if pos_1 != -1
            let pos_2 = stridx(line,":=")
            let generic_port_t = strpart(line,0,pos_1)
            if pos_2 == -1 "没有初值的情况
                let generic_type_t = strpart(line,pos_1+1)
                let generic_value_t = ""
            else "有初值
                let generic_type_t = strpart(line,pos_1+1,pos_2-pos_1-1)
                let generic_value_t = strpart(line,pos_2+2)
            endif
            let s:generic_count = s:generic_count + 1
            call add(s:generic_port,generic_port_t)
            call add(s:generic_value,generic_value_t)
            call add(s:generic_type,generic_type_t)
        endif

"        echo "pos_1= ".pos_1
"        echo "pos_2= ".pos_2
"        echo "generic_port_t= ".generic_port_t
"        echo "generic_type_t= ".generic_type_t
"        echo "generic_value_t= ".generic_value_t
"        echo s:generic_port
"        echo s:generic_value
"        echo s:generic_type
        let i = i + 1
    endwhile

endfunction

"------------------------------------------------------------------------
"Function    : Check_File_Type()
"Decription  : Check file type 
"               if vhdl return 1
"               if verilog return 2
"               if vim return 3
"               others return 0
"------------------------------------------------------------------------
function Check_File_Type()
    if expand("%:e") == "vhd"
        return 1
    elseif expand("%:e") == "v" 
        return 2
    elseif expand("%:e") == "vim" 
        return 3
    else 
        return 0
    endif
endfunction

"-----------------------------------------------------------------------
"Function    : Change_to_vlog_type(port_tp) 
"Decription  : port_tp is std_logic_vector(x downto y)
"               return a string as [x:y] 
"------------------------------------------------------------------------
function Change_to_vlog_type(port_tp)
    if a:port_tp =~ '\<std_logic_vector\>'
        let mid = substitute(a:port_tp,'\<std_logic_vector\>\s*(',"","")
        if a:port_tp =~ '\<downto\>'
            let high_tp = substitute(mid,'\s*\<downto\>.*',"","")
            let low_tp = substitute(mid,'.*\<downto\>\s*',"","")
            let low_tp = substitute(low_tp,'\s*).*',"","")
        elseif a:port_tp =~ '\<to\>'
            let high_tp = substitute(mid,'\s*\<to\>.*',"","")
            let low_tp = substitute(mid,'.*\<to\>\s*',"","")
            let low_tp = substitute(low_tp,'\s*).*',"","")
        else 
            return "Wrong"
        endif
        let vlog_tp = "[".high_tp.":".low_tp."]"
    else 
        return "Wrong"
    endif
    return vlog_tp
endfunction

"------------------------------------------------------------------------
"Function    : Generic_Part_Build(lang) 
"Decription  :  
"------------------------------------------------------------------------

"function Generic_Part_Build(lang)
"    if a:lang == "vhdl"
"        let generic_part = "\tgeneric map (\n"

"------------------------------------------------------------------------
"Function    : Component_Part_Build(lang)
"Decription  : build component part
"------------------------------------------------------------------------
function Component_Part_Build(lang)
    if a:lang == "vhdl"
        let component_part = "\tcomponent ".s:ent_name." is\n"
        if s:generic_start_line != 0
            let component_part = component_part."\tgeneric (\n"
            let i = 0
            while i < s:generic_count 
                if strwidth(s:generic_port[i])<4
                    let component_part = component_part."\t\t".s:generic_port[i]."\t\t\t\t: ".s:generic_type[i]."\t"
                elseif strwidth(s:generic_port[i])<8 && strwidth(s:generic_port[i])>=4
                    let component_part = component_part."\t\t".s:generic_port[i]."\t\t\t: ".s:generic_type[i]."\t"
                elseif strwidth(s:generic_port[i])<12 && strwidth(s:generic_port[i])>=8
                    let component_part = component_part."\t\t".s:generic_port[i]."\t\t: ".s:generic_type[i]."\t"
                elseif strwidth(s:generic_port[i])<16 && strwidth(s:generic_port[i])>=12
                    let component_part = component_part."\t\t".s:generic_port[i]."\t: ".s:generic_type[i]."\t"
                elseif strwidth(s:generic_port[i])>=16
                    let component_part = component_part."\t\t".s:generic_port[i].": ".s:generic_type[i]."\t"
                endif
                if s:generic_value[i] != ""
                    let component_part = component_part.":= ".s:generic_value[i]
                endif
                if i != s:generic_count - 1
                    let component_part = component_part.";\n"
                else
                    let component_part = component_part."\n\t);\n"
                endif
                let i = i + 1
            endwhile
        endif
        let component_part = component_part."\tport (\n"
        let i = 0
        while i < s:port_cout
            if strwidth(s:port[i])<4 
                let component_part = component_part."\t\t".s:port[i]."\t\t\t\t: ".s:direction[i]."\t".s:type[i]
            elseif strwidth(s:port[i])<8 && strwidth(s:port[i])>=4
                let component_part = component_part."\t\t".s:port[i]."\t\t\t: ".s:direction[i]."\t".s:type[i]
            elseif strwidth(s:port[i])<12 && strwidth(s:port[i])>=8
                let component_part = component_part."\t\t".s:port[i]."\t\t: ".s:direction[i]."\t".s:type[i]
            elseif strwidth(s:port[i])>=12 && strwidth(s:port[i])<16
                let component_part = component_part."\t\t".s:port[i]."\t: ".s:direction[i]."\t".s:type[i]
            elseif strwidth(s:port[i])>=16 
                let component_part = component_part."\t\t".s:port[i].": ".s:direction[i]."\t".s:type[i]
            endif
            if i != s:port_cout - 1
                let component_part = component_part.";\n"
            else
                let component_part = component_part."\n\t);\n\tend component;\n\n"
            endif
            let i = i +1
        endwhile
        return component_part
    elseif a:lang == "verilog"
        return ''
    else 
        return ''
    endif
endfunction

"------------------------------------------------------------------------
"Function    : Instant_Part_Build(lang)
"Decription  : build instant_part 
"------------------------------------------------------------------------
function Instant_Part_Build(lang)
    if a:lang == "vhdl"
        let instant_part = "\t".s:ent_name."_inst : ".s:ent_name."\n"
        if s:generic_start_line != 0
            let instant_part = instant_part."\tgeneric map (\n"
            let i = 0
            while i < s:generic_count 
                if strwidth(s:generic_port[i])<4
                    let instant_part = instant_part."\t\t".s:generic_port[i]."\t\t\t\t=> "
                elseif strwidth(s:generic_port[i])<8 && strwidth(s:generic_port[i])>=4
                    let instant_part = instant_part."\t\t".s:generic_port[i]."\t\t\t=> "
                elseif strwidth(s:generic_port[i])<12 && strwidth(s:generic_port[i])>=8
                    let instant_part = instant_part."\t\t".s:generic_port[i]."\t\t=> "
                elseif strwidth(s:generic_port[i])<16 && strwidth(s:generic_port[i])>=12
                    let instant_part = instant_part."\t\t".s:generic_port[i]."\t=> "
                elseif strwidth(s:generic_port[i])>=16
                    let instant_part = instant_part."\t\t".s:generic_port[i]."=> "
                endif
                if s:generic_value[i] != ""
                    let instant_part = instant_part.s:generic_value[i]
                else
                    let instant_part = instant_part.s:generic_port[i]
                endif
                if i != s:generic_count - 1
                    let instant_part = instant_part.",\n"
                else
                    let instant_part = instant_part."\n\t)\n"
                endif
                let i = i + 1
            endwhile
        endif
        let instant_part = instant_part."\tport map(\n"
        let i = 0
        while i < s:port_cout 
            if strwidth(s:port[i])<4
                let instant_part = instant_part."\t\t".s:port[i]."\t\t\t\t=>\t".s:port[i]
            elseif strwidth(s:port[i])<8 && strwidth(s:port[i])>=4
                let instant_part = instant_part."\t\t".s:port[i]."\t\t\t=>\t".s:port[i]
            elseif strwidth(s:port[i])>=8 && strwidth(s:port[i])<12
                let instant_part = instant_part."\t\t".s:port[i]."\t\t=>\t".s:port[i]
            elseif strwidth(s:port[i])>=12 && strwidth(s:port[i])<16
                let instant_part = instant_part."\t\t".s:port[i]."\t=>\t".s:port[i]
            else 
                let instant_part = instant_part."\t\t".s:port[i]."=>\t".s:port[i]
            endif
            if i != s:port_cout -1 
                let instant_part = instant_part.",\n"
            else 
                let instant_part = instant_part."\n\t);\n\n"
            endif
            let i = i + 1
        endwhile
    elseif a:lang == "verilog"
        let instant_part = "\t".s:ent_name
        " ".s:ent_name." (\n"
        "
        if s:generic_start_line != 0
            let i = 0
            let abc = ""
            let instant_part = instant_part."\t#(\n"
            let parameter = ""
            while i < s:generic_count
                if s:generic_value[i] != ""
                    let parameter = parameter."\tparameter\t".s:generic_port[i]." = ".s:generic_value[i].";\n"
                else 
                    let parameter = parameter."\tparameter\t".s:generic_port[i]." = //Add value;\n"
                endif
                if strwidth(s:generic_port[i])<3
                    let instant_part = instant_part."\t\t.".s:generic_port[i]."\t\t\t\t(".s:generic_port[i].")"
                elseif strwidth(s:generic_port[i])<7 && strwidth(s:generic_port[i])>=3
                    let instant_part = instant_part."\t\t.".s:generic_port[i]."\t\t\t(".s:generic_port[i].")"
                elseif strwidth(s:generic_port[i])<11 && strwidth(s:generic_port[i])>=7
                    let instant_part = instant_part."\t\t.".s:generic_port[i]."\t\t(".s:generic_port[i].")"
                elseif strwidth(s:generic_port[i])<15 && strwidth(s:generic_port[i])>=11
                    let instant_part = instant_part."\t\t.".s:generic_port[i]."\t(".s:generic_port[i].")"
                else
                    let instant_part = instant_part."\t\t.".s:generic_port[i]."(".s:generic_port[i].")"
                endif
                if i != s:generic_count - 1
                    let instant_part = instant_part.",\n"
                else 
                    let instant_part = instant_part."\n\t)\n"
                endif
                let i = i + 1
            endwhile
            let instant_part = parameter."\n".instant_part
        endif
        
        let instant_part = instant_part."\t".s:ent_name." (\n"

        let i = 0
        while i < s:port_cout
            if strwidth(s:port[i])<3
                let instant_part = instant_part."\t\t.".s:port[i]."\t\t\t\t(".s:port[i]
            elseif strwidth(s:port[i])<7 && strwidth(s:port[i])>=3
                let instant_part = instant_part."\t\t.".s:port[i]."\t\t\t(".s:port[i]
            elseif strwidth(s:port[i])>=7 && strwidth(s:port[i])<11
                let instant_part = instant_part."\t\t.".s:port[i]."\t\t(".s:port[i]
            elseif strwidth(s:port[i])>=11 && strwidth(s:port[i]) <15
                let instant_part = instant_part."\t\t.".s:port[i]."\t(".s:port[i]
            else
                let instant_part = instant_part."\t\t.".s:port[i]."(".s:port[i]
            endif
            if i != s:port_cout - 1
                let instant_part = instant_part."),\n"
            else 
                let instant_part = instant_part.")\n\t);\n\n"
            endif
            let i = i + 1
        endwhile
    elseif
        return ''
    endif
    return instant_part
endfunction

"------------------------------------------------------------------------
"Function    : Inport_Part_Build(lang) 
"Decription  : inport part 
"------------------------------------------------------------------------
function Inport_Part_Build(lang)
    if a:lang == "vhdl"
        let inport_part = "\t-- Inputs\n"
        let i = 0 
        while i < s:port_cout 
            if s:direction[i] == "in"
                if strwidth(s:port[i])<4
                    let inport_part = inport_part."\tsignal\t".s:port[i]."\t\t\t\t: ".s:type[i]
                elseif strwidth(s:port[i])<8 && strwidth(s:port[i])>=4
                    let inport_part = inport_part."\tsignal\t".s:port[i]."\t\t\t: ".s:type[i]
                elseif strwidth(s:port[i])>=8 && strwidth(s:port[i])<12
                    let inport_part = inport_part."\tsignal\t".s:port[i]."\t\t: ".s:type[i]
                elseif strwidth(s:port[i])>=12 && strwidth(s:port[i])<16 
                    let inport_part = inport_part."\tsignal\t".s:port[i]."\t: ".s:type[i]
                elseif strwidth(s:port[i])>=16
                    let inport_part = inport_part."\tsignal\t".s:port[i].": ".s:type[i]
                endif
                if s:type[i] =~ '\<std_logic_vector\>'
                    let inport_part = inport_part.":=(others=>'0');\n"
                else
                    let inport_part = inport_part.":='0';\n"
                endif
            endif
            let i = i + 1
        endwhile   
    elseif a:lang == "verilog"
        let inport_part = "\t// Inputs\n"
        let i = 0
        while i < s:port_cout 
            if s:direction[i] == "in"
                if s:type[i] =~ '\<std_logic_vector\>'
                    let inport_part = inport_part."\treg\t\t".Change_to_vlog_type(s:type[i])."\t".s:port[i].";\n"
                else 
                    let inport_part = inport_part."\treg\t\t\t\t".s:port[i].";\n"
                endif
            endif
            let i = i + 1
        endwhile
    else 
        return ''
    endif
    return inport_part
endfunction

"------------------------------------------------------------------------
"Function    : Outport_Part_Build(lang) 
"Decription  : outport part 
"------------------------------------------------------------------------
function Outport_Part_Build(lang)
    if a:lang == "vhdl"
        let outport_part = "\t-- Outputs\n"
        let i = 0 
        while i < s:port_cout 
            if s:direction[i] == "out"
                if strwidth(s:port[i])<4
                    let outport_part = outport_part."\tsignal\t".s:port[i]."\t\t\t\t: ".s:type[i]
                elseif strwidth(s:port[i])<8 && strwidth(s:port[i])>=4
                    let outport_part = outport_part."\tsignal\t".s:port[i]."\t\t\t: ".s:type[i]
                elseif strwidth(s:port[i])>=8 && strwidth(s:port[i])<12
                    let outport_part = outport_part."\tsignal\t".s:port[i]."\t\t: ".s:type[i]
                elseif strwidth(s:port[i])>=12  && strwidth(s:port[i])<16
                    let outport_part = outport_part."\tsignal\t".s:port[i]."\t: ".s:type[i]
                elseif strwidth(s:port[i])>=16
                    let outport_part = outport_part."\tsignal\t".s:port[i].": ".s:type[i]
                endif
                let outport_part = outport_part.";\n"
            endif
            let i = i + 1
        endwhile   
    elseif a:lang == "verilog"
        let outport_part = "\t// Outputs\n"
        let i = 0
        while i < s:port_cout 
            if s:direction[i] == "out"
                if s:type[i] =~ '\<std_logic_vector\>'
                    let outport_part = outport_part."\twire\t".Change_to_vlog_type(s:type[i])."\t".s:port[i].";\n"
                else 
                    let outport_part = outport_part."\twire\t\t\t".s:port[i].";\n"
                endif
            endif
            let i = i + 1
        endwhile
    else 
        return ''
    endif
    return outport_part
endfunction

"------------------------------------------------------------------------------
"Function  : Component_Build() 
"Arguments : Open a new window and put component information on it ;
"            The information also put in the register +.
"------------------------------------------------------------------------------
function Component_Build(type)
    if a:type == ''
        echo "Do not set \"type\""
        return
    endif
"    Check the file type
    if Check_File_Type() != 1
        echohl ErrorMsg
        echo    "File type is Wrong!It is not a vhdl file..."
        echohl None
        return
    endif
    let s:bur_num = bufnr(expand("%"))
"    get information of the entity
    if !Get_Information_Of_Entity() 
        return
    endif
"    build the component information
    if a:type == "vhdl"
        let component_part = Component_Part_Build("vhdl")."\n"
    elseif a:type == "verilog"
        let component_part = ''
    endif
    let inport_part = Inport_Part_Build(a:type)."\n"
    let outport_part = Outport_Part_Build(a:type)."\n"
    let instant_part = Instant_Part_Build(a:type)."\n"
    let all_part = component_part.inport_part.outport_part.instant_part
"    let @+ = all_part
    let @* = all_part
"    build component window
    let sp_op = ''
    if exists('g:RightB_Commponent')
        if g:RightB_Commponent
            let sp_op = "rightbelow vertical "
        else 
            let sp_op = "vertical "
        endif
    endif
    exe sp_op."split __Instant_File__"
    if sp_op == ''
        exe "resize ".g:Height_of_Component
    else
        exe "vertical resize ".g:Width_of_Component
    endif
    silent put! =all_part
    exe "normal gg"
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete
    if a:type == "vhdl"
        setlocal filetype=vhdl
    elseif a:type == "verilog"
        setlocal filetype=verilog
    endif
endfunction


"-----------------------------------------------------------------------
"Function    : Tb_Vhdl_Build() 
"Decription  :  
"------------------------------------------------------------------------
function Tb_Vhdl_Build(type)
    if a:type == ''
        echo "Do not set \"type\""
        return
    endif
"  Check the file type
    if !Check_File_Type()
        echohl ErrorMsg
        echo    "This file type is not supported!"
        echohl None
        return
    endif
"    get information of the entity
    if !Get_Information_Of_Entity() 
        return
    endif
    if !exists('clk')
        let clk = "clk"
    endif
    if !exists('rst')
        let rst = "rst"
    endif
"    file name and entity name 
    let tb_ent_name = "tb_".s:ent_name
    if a:type == "vhdl"
        let tb_file_name = "tb_".s:ent_name.".vhd"
        let entity_part = "entity ".tb_ent_name." is\nend ".tb_ent_name.";\n\n"
        let architecture_part = "architecture behavior of ".tb_ent_name.
                    \" is\n\n\t-- Component Declaration for the Unit Under Test (UUT)\n"
        let constant_part = "\t-- Clock period definitions\n\tconstant clk_period : time := ".g:HDL_Clock_Period
                    \." ns;\n\nbegin\n\n"
        let clock_part = "\t-- Clock process definitions\n\tprocess\n\tbegin\n\t\t".clk
                    \." <= '0';\n\t\twait for clk_period/2;\n\t\t".clk." <= '1';\n"
                    \."\t\twait for clk_period/2;\n\tend process;\n\n"
        let simulus_part = "\t-- Stimulus process\n\tprocess\n\tbegin\n\t\t-- hold reset state for 100 ns\n"
                    \."\t\twait for 100 ns;\n\t\trst <= '0';\n\n\t\twait for 10000 ns;\n\n"
                    \."\t\t-- Add stimulus here\n\n\t\twait;\n\tend process;\n\nend behavior;\n"
    elseif a:type == "verilog"
        let tb_file_name = "tb_".s:ent_name.".v"
        let entity_part = ''
        let architecture_part = "module ".tb_ent_name.";\n\n"
        let constant_part = ''
        let half_clk = g:HDL_Clock_Period/2
        let clock_part = "\t// Clock generate \n\talways # ".half_clk."\t".clk." <= ~".clk.";\n\n"
        let simulus_part = "\tinitial begin\n\t\t// Initialize Inputs\n"
        let i = 0
        while i < s:port_cout
            if s:direction[i] == "in"
                let simulus_part = simulus_part."\t\t".s:port[i]." = 0;\n"
            endif
            let i = i + 1
        endwhile
        let simulus_part = simulus_part."\n\t\t// Wait 100 ns for global reset to finish\n"
                    \."\t\t#100;\n\t\trst = 0;\n\n\t\t// Add stimulus here\n\n\tend\n\nendmodule\n"
    endif
     "    component part
    let component_part = Component_Part_Build(a:type)
    let inport_part = Inport_Part_Build(a:type)."\n"
    let outport_part = Outport_Part_Build(a:type)."\n"
    let instant_part = Instant_Part_Build(a:type)
    let all_part = entity_part.architecture_part.component_part.inport_part.outport_part
                \.constant_part.instant_part.clock_part.simulus_part
"    检测文件是否已经存在 
    if filewritable(tb_file_name) 
        let choice = confirm("The testbench file has been exist.\nSelect \"Open\" to open existed file.".
                    \"\nSelect \"Change\" to replace it.\nSelect \"Cancel\" to Cancel this operation.",
                    \"&Open\nCh&ange\n&Cancel")
        if choice == 0
            echo "\"Create a Testbench file\" be Canceled!"
            return
        elseif choice == 1
            exe "bel sp ".tb_file_name
            return
        elseif choice == 2
            if delete(tb_file_name) 
                echohl ErrorMsg
                echo    "The testbench file already exists.But now can't Delete it!"
                echohl None
                return
            else 
                echo "The testbench file already exists.Delete it and recreat a new one!"
            endif
        else 
            echo "\"Create a Testbench file\" be Canceled!"
            return
        endif
    endif
    exe "bel sp ".tb_file_name
    silent put! =all_part
    exe "AddInfo"
    if search('\<rst\>.*=') != 0
        exe "normal f0r1"
    endif
    exe "up"
    call search("Add stimulus here")
endfunction

"------------------------------------------------------------------------------
"Function    : LastModified() 
"Description : Add modifiled time to the file's annotation  
"------------------------------------------------------------------------------
function LastModified()
    let l = line("$")
    execute "1," . l . "g/Last Modified\t:/s/Last Modified\t:.*/Last Modified\t: " .
        \ strftime("%Y-%m-%d %H:%M")
endfunction
autocmd BufWritePre,FileWritePre *.vhd   ks|call LastModified()|'s
autocmd BufWritePre,FileWritePre *.v   ks|call LastModified()|'s

"------------------------------------------------------------------------------
"Function    : CloseComponetFiles() 
"Description : Auto Close the Component file when close the vhd file 
"------------------------------------------------------------------------------
function CloseComponetFiles()
    if bufloaded("__Instant_File__") 
        if bufloaded(g:TagList_title)
            exe "bdelete! __Instant_File__" 
        else
            exe "bdelete! __Instant_File__"
            exe "q!"
        endif
    endif 
endfunction
autocmd BufUnload   *.vhd call CloseComponetFiles() 

