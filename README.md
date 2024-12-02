# zsh-aws-ssm-vault
Plugin para oh-my-zsh para interagir, via shell, com o AWS SSM Parameter Store


## Requisitos
Este plugin depende do AWS CLI instalado e devidamente configurado (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) e do pacote jq. 
Deve haver uma variável de ambiente ZSH_AWS_PROFILE definida como profile padrão do plugin


## Uso
Função get_ssm_parameter()
get_ssm_parameter [-v] nome_do_parametro [--profile profile_name]
- -v: verbose
- nome_do_parametro: nome do parâmetro do SSM Paremeter Store
- --profile: nome do profile caso use um AWS CLI profile diferente do padrão, definido em ZSH_AWS_PROFILE

Função set_ssm_parameter()
set_ssm_parameter [-v] --name "/nome/chave/configuracao" --value "valor" [--type String|SecureString] [--profile profile_name]
- -v: verbose
- --name: nome do parâmetro dentro do SSM Parameter Store
- --value: valor do parâmetro
- --type: se o tipo é String (default) ou SecureString (criptografado)
- --profile: nome do profile caso use um AWS CLI profile diferente do padrão, definido em ZSH_AWS_PROFILE

Função list_ssm_parameter()
list_ssm_parameters [-v] [--profile profile_name] [--with-values]
- -v: verbose
- --profile: nome do profile caso use um AWS CLI profile diferente do padrão, definido em ZSH_AWS_PROFILE
- --with_values: retorna a lista de parâmetros com seus valores

## Autor
Luiz A. Amelotti <luiz@amelotti.com>
