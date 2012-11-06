#!/usr/bin/perl -w

use Test::More tests => 2;

use Alert::Handler::Email;

my $email = 'Return-Path: gschoenberger@thomas-krenn.com
Received: from zimbra.thomas-krenn.com (LHLO zimbra.thomas-krenn.com)
 (127.0.1.1) by zimbra.thomas-krenn.com with LMTP; Mon, 5 Nov 2012 15:08:10
 +0100 (CET)
Received: from localhost (localhost [127.0.0.1])
        by zimbra.thomas-krenn.com (Postfix) with ESMTP id 7CCCA6FC14F
        for <gschoenberger@thomas-krenn.com>; Mon,  5 Nov 2012 15:08:10 +0100 (CET)
X-Virus-Scanned: amavisd-new at thomas-krenn.com
X-Spam-Flag: NO
X-Spam-Score: 1.66
X-Spam-Level: *
X-Spam-Status: No, score=1.66 tagged_above=-10 required=6.6
        tests=[BAYES_40=-0.001, HELO_NO_DOMAIN=0.001, RDNS_NONE=0.793,
        TO_EQ_FM_DIRECT_MX=0.867] autolearn=no
Received: from zimbra.thomas-krenn.com ([127.0.0.1])
        by localhost (zimbra.thomas-krenn.com [127.0.0.1]) (amavisd-new, port 10024)
        with ESMTP id 8gezUBqaX3f0 for <gschoenberger@thomas-krenn.com>;
        Mon,  5 Nov 2012 15:08:10 +0100 (CET)
Received: from zimbra.thomas-krenn.com (zimbra.thomas-krenn.com [127.0.1.1])
        by zimbra.thomas-krenn.com (Postfix) with ESMTP id 377216FC14D
        for <gschoenberger@thomas-krenn.com>; Mon,  5 Nov 2012 15:08:10 +0100 (CET)
Date: Mon, 5 Nov 2012 15:08:10 +0100 (CET)
From: Georg =?utf-8?Q?Sch=C3=B6nberger?= <gschoenberger@thomas-krenn.com>
To: Georg =?utf-8?Q?Sch=C3=B6nberger?= <gschoenberger@thomas-krenn.com>
Message-ID: <785398640.522344.1352124490165.JavaMail.root@thomas-krenn.com>
Subject: TK-Monitoring Test E-Mail
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 7bit
X-Originating-IP: [91.223.201.11]
X-Mailer: Zimbra 7.2.0_GA_2669 (ZimbraWebClient - FF3.0 (Linux)/7.2.0_GA_2669)

The quick brown fox jumps over the lazy dog.';

is(getSubject($email), 'TK-Monitoring Test E-Mail');
my $modifiedEmail = replaceSubject($email,'TK-Monitoring modified Subject');
is(getSubject($modifiedEmail), 'TK-Monitoring modified Subject');

