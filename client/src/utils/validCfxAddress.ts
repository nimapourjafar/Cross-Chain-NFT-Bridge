

export function validCfxAddress(address: string): boolean {
    // cfx address example: cfx:aak2rra2njvd77ezwjvx04kkds9fzagfe6ku8scz91
    return /cfx:([a-z0-9A-Z]{42})/.test(address) || /cfxtest:([a-z0-9A-Z]{42})/.test(address);   
}