# ==============================================================================
# configs/ssh-hosts.example.ps1 — Template de hosts SSH
# Copie para configs/ssh-hosts.ps1 e preencha com seus servidores reais.
# configs/ssh-hosts.ps1 está no .gitignore.
# ==============================================================================

$global:SSH_KEY  = "$HOME\.ssh\id_rsa"   # Caminho da chave privada
$global:SSH_USER = "seu_usuario"          # Usuário padrão (sobrescrito por host)

$global:SSH_HOSTS = @{
    # Formato: "alias" = @{ Host="ip_ou_hostname"; Port=22; User="usuario" }

    # Exemplos:
    "nas"         = @{ Host = "192.168.0.10";   Port = 22;   User = "admin"   }
    "pi"          = @{ Host = "192.168.0.101";  Port = 22;   User = "pi"      }
    "servidor"    = @{ Host = "192.168.0.145";  Port = 22;   User = "bruno"   }
    "vps"         = @{ Host = "0.0.0.0";        Port = 22;   User = "ubuntu"  }
    "docker"      = @{ Host = "0.0.0.0";        Port = 9022; User = "deploy"  }
}
