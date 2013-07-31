extrn SysCallCallback:proc
extrn RdmsrHook:proc
extrn PageFault:proc

include ..\Common\amd64\common.inc

.code

get_ring3_rsp proc
	mov rax, qword ptr gs:[Ring3RSP]
	ret
get_ring3_rsp endp

sysenter proc
	swapgs
	mov qword ptr gs:[Ring3RSP],rsp
	mov rsp,qword ptr gs:[Ring0RSP]

_hook:
	ENTER_HOOK_PROLOGUE
	ENTER_HOOK SysCallCallback
	
	cmp rax, 0
	jz @syscall_skip

	add rax, _hook - sysenter
	ENTER_HOOK_EPILOGUE
	ret

@syscall_skip:
	ENTER_HOOK_EPILOGUE

	mov rsp, qword ptr gs:[Ring3RSP]	
	swapgs	
	sysretq ; return back to user mode
sysenter endp

rdmsr_hook proc
	ENTER_HOOK_PROLOGUE
	ENTER_HOOK RdmsrHook
	ENTER_HOOK_EPILOGUE
	ret
rdmsr_hook endp

pagafault_hook proc
;previous mode kernel mode ??
	test byte ptr [rsp + 2 * sizeof(QWORD)], 1
	je @noswap_prolog
	swapgs

@noswap_prolog:
	ENTER_HOOK_PROLOGUE	
	ENTER_HOOK PageFault
	
	test byte ptr  [rsp + 3 * sizeof(QWORD)], 1
	je @noswap_epilog
	swapgs

@noswap_epilog:
	cmp rax, 0
	ENTER_HOOK_EPILOGUE
	jz @access_allowed	
	
	ret 

@access_allowed:
	popptr;pop original nt!kipagefault
	popptr;previous mode
	iretq ; return back to user mode
pagafault_hook endp

syscall_instr_prologue proc
	syscall
syscall_instr_prologue endp
syscall_instr_epilogue proc
	sysretq
syscall_instr_epilogue endp

end