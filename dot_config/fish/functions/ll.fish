# ls -lrt equivalent (long format, sorted by modification time, newest first)
function ll --description 'ls -lrt equivalent'
    if command -q eza
        eza -l --sort=modified --color=auto $argv
    else if command -q gls
        gls -lrt --color=auto $argv
    else
        command ls -lrt $argv
    end
end
