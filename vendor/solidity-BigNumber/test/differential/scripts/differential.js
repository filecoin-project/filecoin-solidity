"use strict";
exports.__esModule = true;
var bn_js_1 = require("bn.js");
var ethers_1 = require("ethers");
var func = process.argv[2];
switch (func) {
    case "add": {
        var a_val = process.argv[3].substring(2);
        var b_val = process.argv[4].substring(2);
        var a_neg = (process.argv[5] === 'true');
        var b_neg = (process.argv[6] === 'true');
        var a = new bn_js_1.BN(a_val, 16);
        var b = new bn_js_1.BN(b_val, 16);
        if (a_neg)
            a = a.mul(new bn_js_1.BN(-1));
        if (b_neg)
            b = b.mul(new bn_js_1.BN(-1));
        var res_1 = a.add(b);
        var neg = res_1.isNeg();
        if (neg)
            res_1 = res_1.abs();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res_1.toString())]));
        break;
    }
    case "sub": {
        var a_val = process.argv[3].substring(2);
        var b_val = process.argv[4].substring(2);
        var a_neg = (process.argv[5] === 'true');
        var b_neg = (process.argv[6] === 'true');
        var a = new bn_js_1.BN(a_val, 16);
        var b = new bn_js_1.BN(b_val, 16);
        if (a_neg)
            a = a.mul(new bn_js_1.BN(-1));
        if (b_neg)
            b = b.mul(new bn_js_1.BN(-1));
        var res_2 = a.sub(b);
        var neg = res_2.isNeg();
        if (neg)
            res_2 = res_2.abs();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res_2.toString())]));
        break;
    }
    case "mul": {
        var a_val = process.argv[3].substring(2);
        var b_val = process.argv[4].substring(2);
        var a_neg = (process.argv[5] === 'true');
        var b_neg = (process.argv[6] === 'true');
        var a = new bn_js_1.BN(a_val, 16);
        var b = new bn_js_1.BN(b_val, 16);
        if (a_neg)
            a = a.mul(new bn_js_1.BN(-1));
        if (b_neg)
            b = b.mul(new bn_js_1.BN(-1));
        var res_3 = a.mul(b);
        var neg = res_3.isNeg();
        if (neg)
            res_3 = res_3.abs();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res_3.toString())]));
        break;
    }
    case "div": {
        var a_val = process.argv[3].substring(2);
        var b_val = process.argv[4].substring(2);
        var a_neg = (process.argv[5] === 'true');
        var b_neg = (process.argv[6] === 'true');
        var a = new bn_js_1.BN(a_val, 16);
        var b = new bn_js_1.BN(b_val, 16);
        if (a_neg)
            a = a.mul(new bn_js_1.BN(-1));
        if (b_neg)
            b = b.mul(new bn_js_1.BN(-1));
        var res_4 = a.div(b);
        var neg = res_4.isNeg();
        if (neg)
            res_4 = res_4.abs();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res_4.toString())]));
        break;
    }
    case "invmod": {
        var a_val = process.argv[3].substring(2);
        var m_val = process.argv[4].substring(2);
        var a = new bn_js_1.BN(a_val, 16);
        var m = new bn_js_1.BN(m_val, 16);
        var res_5 = a.invm(m);
        var neg = res_5.isNeg();
        if (neg)
            res_5 = res_5.mul(new bn_js_1.BN(-1));
        var valid = a.mul(res_5).mod(m).eq(new bn_js_1.BN(1));
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bool', 'bytes'], [valid, neg, ethers_1.ethers.BigNumber.from(res_5.toString())]));
        break;
    }
    case "mod": {
        var a_val = process.argv[3].substring(2);
        var n_val = process.argv[4].substring(2);
        var a_neg = (process.argv[5] === 'true');
        var a = new bn_js_1.BN(a_val, 16);
        var n = new bn_js_1.BN(n_val, 16);
        if (a_neg)
            a = a.mul(new bn_js_1.BN(-1));
        var res_6 = a.umod(n);
        var neg = res_6.isNeg();
        if (neg)
            res_6 = res_6.abs();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res_6.toString())]));
        break;
    }
    case "shl": {
        var a_val = process.argv[3].substring(2);
        var bits = Number(process.argv[4]);
        var a = new bn_js_1.BN(a_val, 16);
        var res_7 = a.shln(bits);
        var neg = res_7.isNeg();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res_7.toString())]));
        break;
    }
    case "shr": {
        var a_val = process.argv[3].substring(2);
        var bits = Number(process.argv[4]);
        var a = new bn_js_1.BN(a_val, 16);
        var res_8 = a.shrn(bits);
        var neg = res_8.isNeg();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res_8.toString())]));
        break;
    }
    case "cmp": {
        var a_val = process.argv[3].substring(2);
        var b_val = process.argv[4].substring(2);
        var a_neg = (process.argv[5] === 'true');
        var b_neg = (process.argv[6] === 'true');
        var signed = (process.argv[7] === 'true');
        var a = new bn_js_1.BN(a_val, 16);
        var b = new bn_js_1.BN(b_val, 16);
        if (signed) {
            if (a_neg)
                a = a.mul(new bn_js_1.BN(-1));
            if (b_neg)
                b = b.mul(new bn_js_1.BN(-1));
        }
        var res_9 = 0;
        if (a.gt(b))
            res_9 = 1;
        else if (a.lt(b))
            res_9 = -1;
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['int'], [res_9]));
        break;
    }
    case "modmul": {
        var a_val = process.argv[3].substring(2);
        var b_val = process.argv[4].substring(2);
        var n_val = process.argv[5].substring(2);
        var a_neg = (process.argv[6] === 'true');
        var b_neg = (process.argv[7] === 'true');
        var a = new bn_js_1.BN(a_val, 16);
        var b = new bn_js_1.BN(b_val, 16);
        var n = new bn_js_1.BN(n_val, 16);
        if (a_neg)
            a = a.mul(new bn_js_1.BN(-1));
        if (b_neg)
            b = b.mul(new bn_js_1.BN(-1));
        var res_10 = a.mul(b).umod(n);
        var neg = res_10.isNeg();
        if (neg)
            res_10 = res_10.abs();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res_10.toString())]));
        break;
    }
    case "modexp": {
        var a_val = process.argv[3].substring(2);
        var e_val = process.argv[4].substring(2);
        var m_val = process.argv[5].substring(2);
        var a = new bn_js_1.BN(a_val, 16);
        var e = new bn_js_1.BN(e_val, 16);
        var m = new bn_js_1.BN(m_val, 16);
        var reducedA = a.toRed(bn_js_1.BN.red(m));
        var reducedRes = reducedA.redPow(e);
        var res = reducedRes.fromRed();
        var neg = res.isNeg();
        if (neg)
            res = res.abs();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers_1.ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "iszero": {
        var a_val = process.argv[3];
        var a_neg = (process.argv[4] === 'true');
        var a = new bn_js_1.BN(a_val, 16);
        if (a_neg)
            a = a.mul(new bn_js_1.BN(-1));
        var res_11 = a.isZero();
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool'], [ethers_1.ethers.BigNumber.from(res_11.toString())]));
        break;
    }
}
