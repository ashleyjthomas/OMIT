"""Single source of truth for OMIT3 CHS: contents, trials, narration texts, versions.
Writes chs/design.json (read by omit3_task.js) and is imported by make_audio.py."""
import json, csv, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# ---------------------------------------------------------------- contents
# key -> how the content is talked about and drawn
CONTENTS = {
    # emotions (icon is protagonist-specific mini portrait)
    'sad':   dict(kind='emotion', told='about feeling sad today',   est='At school today, {P} felt sad, and {P} didn\'t know why.',
                  mem='Which classmate did {P} tell about feeling sad today?'),
    'happy': dict(kind='emotion', told='about feeling happy today', est='At school today, {P} felt happy, and {P} didn\'t know why.',
                  mem='Which classmate did {P} tell about feeling happy today?'),
    # facts
    'fox':      dict(kind='fact', icon='fox', told='about how foxes move without making any sound',
                     est='In school today, {P} learned that foxes move without making any sound.',
                     mem='Which classmate did {P} tell the fact about foxes?'),
    'elephant': dict(kind='fact', icon='elephant', told='about how elephants move mostly in the morning',
                     est='In school today, {P} learned that elephants move mostly in the morning.',
                     mem='Which classmate did {P} tell the fact about elephants?'),
    'rabbit':   dict(kind='fact', icon='rabbit', told='about how rabbits move by hopping on their back legs',
                     est='In school today, {P} learned that rabbits move by hopping on their back legs.',
                     mem='Which classmate did {P} tell the fact about rabbits?'),
    'owl':      dict(kind='fact', icon='owl', told='about how owls can turn their heads almost all the way around',
                     est='In school today, {P} learned that owls can turn their heads almost all the way around.',
                     mem='Which classmate did {P} tell the fact about owls?'),
    # personal preferences
    'owl_fav':    dict(kind='pref', icon='owl_fav', told='that they found out owls are their favorite animal',
                       est='In school today, {P} found out that owls are their favorite animal.',
                       mem='Which classmate did {P} tell that they found out owls are their favorite animal?'),
    'rabbit_fav': dict(kind='pref', icon='rabbit_fav', told='that they found out rabbits are their favorite animal',
                       est='In school today, {P} found out that rabbits are their favorite animal.',
                       mem='Which classmate did {P} tell that they found out rabbits are their favorite animal?'),
}

TRIALS = {
    'SH': dict(prot='Casey',   c1='Blake',  c2='Morgan',  hi='sad',   lo='happy'),
    'SF': dict(prot='Percy',   c1='Avery',  c2='Orin',    hi='sad',   lo='fox'),
    'HF': dict(prot='Kendall', c1='Riley',  c2='Cameron', hi='happy', lo='elephant'),
    # PF hi/lo depend on the version (pf_fav): owl_fav+rabbit or rabbit_fav+owl
    'PF': dict(prot='Jamie',   c1='Elliot', c2='Parker',  hi=None,    lo=None),
}

# SH establishing lines name the place (scene counterbalance)
SH_EST = {
    ('sad', 'lunch room'):  'Today at lunch, Casey felt sad, and Casey didn\'t know why.',
    ('sad', 'playground'):  'Today at recess, Casey felt sad, and Casey didn\'t know why.',
    ('happy', 'lunch room'): 'Today at lunch, Casey felt happy, and Casey didn\'t know why.',
    ('happy', 'playground'): 'Today at recess, Casey felt happy, and Casey didn\'t know why.',
}

PRACTICE = dict(prot='Sam', best='Quinn', friend='Rowan')

# ---------------------------------------------------------------- versions
VERSIONS = {}
with open(os.path.join(ROOT, '..', 'OMIT3_versions.csv')) as f:
    for r in csv.DictReader(f):
        v = VERSIONS.setdefault(r['version'], dict(order=[], hi_to={}, sh_emotion_first=None, sh_sad_scene=None,
                                                   pf_fav=None, practice_best_side=None, dv_item_first=None))
        v['order'].append(r['trial'])
        v['hi_to'][r['trial']] = 1 if r['higher_rung_told_to'] == 'classmate 1' else 2
        if r['trial'] == 'SH':
            v['sh_emotion_first'] = r['sh_emotion_first']; v['sh_sad_scene'] = r['sh_sad_scene']
        if r['trial'] == 'PF':
            v['pf_fav'] = r['pf_favourite_animal']
        v['practice_best_side'] = r['practice_best_friend_side']
        v['dv_item_first'] = r['dv_item_first']
assert len(VERSIONS) == 8, VERSIONS.keys()

# ---------------------------------------------------------------- narration
N = {}   # audio key -> text

def enc_meet(P, C, first):
    lead = f'After school, {P} saw a classmate named {C}.' if first else f'Then {P} saw another classmate named {C}.'
    return f'{lead} {C} said, "Hi {P}! How was school today?"'

def enc_told(P, C, phrase):
    return f'{P} told {C} {phrase}.'

def enc_nottold(P, C, cd):
    # emotion: "didn't say anything about being sad"; fact: "didn't say anything about how foxes...";
    # preference: "didn't say that they found out owls are their favorite animal"
    if cd['kind'] == 'emotion':
        return f"{P} didn't say anything about being {cd['told'].split()[-2]}."
    if cd['kind'] == 'fact':
        return f"{P} didn't say anything {cd['told']}."
    return f"{P} didn't say {cd['told']}."

def nottold_to(P, C, cd):
    if cd['kind'] == 'emotion':
        return f"{P} didn't say anything to {C} about being {cd['told'].split()[-2]}."
    if cd['kind'] == 'fact':
        return f"{P} didn't tell {C} anything {cd['told']}."
    return f"{P} didn't tell {C} {cd['told']}."

for t, d in TRIALS.items():
    P = d['prot']
    N[f'{t}_intro'] = f'This is {P}. I\'m going to tell you a story about what happened to {P} at school today.'
    contents = ['owl_fav', 'rabbit', 'rabbit_fav', 'owl'] if t == 'PF' else [d['hi'], d['lo']]
    for c in contents:
        cd = CONTENTS[c]
        if t == 'SH':
            for scene in ('lunch room', 'playground'):
                N[f'{t}_est_{c}_{"lunch" if scene == "lunch room" else "recess"}'] = SH_EST[(c, scene)]
        else:
            N[f'{t}_est_{c}'] = cd['est'].format(P=P)
        for ci, C in ((1, d['c1']), (2, d['c2'])):
            N[f'{t}_meet{ci}'] = enc_meet(P, C, first=(ci == 1))
            N[f'{t}_enc{ci}_told_{c}'] = enc_told(P, C, cd['told'])
            N[f'{t}_enc{ci}_nottold_{c}'] = enc_nottold(P, C, cd)
        if True:   # yes/no checks for every content, one per classmate
            for ci, C in ((1, d['c1']), (2, d['c2'])):
                q = f'Did {P} tell {C} {cd["told"]}?'
                N[f'{t}_yn{ci}_{c}'] = q
                N[f'{t}_ynfix{ci}_{c}_yes'] = f'Actually, {P} told {C} {cd["told"]}. Let\'s try again. {q}'
                N[f'{t}_ynfix{ci}_{c}_no'] = f'Actually, ' + nottold_to(P, C, cd) + f' Let\'s try again. {q}'
    # recap after the comprehension checks: both classmates, what each was and was not told.
    # One line per (higher-rung content, which classmate got it) -> 2 for SH/SF/HF, 4 for PF.
    pairs = [('owl_fav', 'rabbit'), ('rabbit_fav', 'owl')] if t == 'PF' else [(d['hi'], d['lo'])]
    for hi_c, lo_c in pairs:
        for hi_to, tag in ((1, 'A'), (2, 'B')):
            told1, not1 = (hi_c, lo_c) if hi_to == 1 else (lo_c, hi_c)
            told2, not2 = (not1, told1)
            C1, C2 = d['c1'], d['c2']
            # one segment per classmate, so that classmate's row can shake while its line plays
            N[f'{t}_recap_{hi_c}_{tag}_1'] = (
                f'So, to remind you. {P} did tell {C1} {CONTENTS[told1]["told"]}, '
                f'but {P} didn\'t tell {C1} {CONTENTS[not1]["told"]}.')
            N[f'{t}_recap_{hi_c}_{tag}_2'] = (
                f'And {P} did tell {C2} {CONTENTS[told2]["told"]}, '
                f'but {P} didn\'t tell {C2} {CONTENTS[not2]["told"]}.')
    N[f'{t}_dv_friend'] = f'Who do you think {P} is better friends with?'
    N[f'{t}_dv_icecream'] = f'Who do you think {P} would want to share the ice cream with, even though they\'d have to lick the same ice cream cone?'
    N[f'{t}_dv_candy'] = f'Who do you think {P} would want to share candy with, by sharing a few of the candies?'

S, B, F = PRACTICE['prot'], PRACTICE['best'], PRACTICE['friend']
N['pr_intro'] = f'Before we start, let\'s practice. This is {S}.'
N['pr_friend1_best'] = f'{S} has two friends. This is {B}. {B} is {S}\'s best friend.'
N['pr_friend2_friend'] = f'And this is {F}. {F} is {S}\'s friend.'
N['pr_friend1_friend'] = f'{S} has two friends. This is {F}. {F} is {S}\'s friend.'
N['pr_friend2_best'] = f'And this is {B}. {B} is {S}\'s best friend.'
N['pr_bestfriend'] = f'Who is {S}\'s best friend? Click on {S}\'s best friend.'
N['pr_bestfriend_wrong'] = f'Hmm, that is {S}\'s friend. Can you click on {S}\'s best friend?'
N['pr_bestfriend_right'] = f'That\'s right! {B} is {S}\'s best friend.'
N['pr_friend_q'] = f'Who do you think {S} is better friends with:'
# the two practice sharing items are the test items, word for word, with Sam in place of the
# protagonist and ending in ':' because the two named options are read straight after
N['pr_icecream'] = f'Who do you think {S} would want to share the ice cream with, even though they\'d have to lick the same ice cream cone:'
N['pr_candy'] = f'Who do you think {S} would want to share candy with, by sharing a few of the candies:'
# option labels read after a practice question, in left-to-right order (the named character shakes)
N['pr_best_first'] = f'{B}, {S}\'s best friend,'
N['pr_friend_second'] = f'or {F}, {S}\'s friend?'
N['pr_friend_first'] = f'{F}, {S}\'s friend,'
N['pr_best_second'] = f'or {B}, {S}\'s best friend?'
N['mem_right'] = 'That\'s right!'
N['why'] = 'Why do you think that? If you need help typing, tell your grown-up and they can type in what you say.'
N['fr_welcome'] = 'Hi! Today we are going to hear some stories about some kids, and I am going to ask you what you think.'
N['fr_start'] = 'Let\'s get started!'
N['fr_click'] = 'Now you can click on one of them.'
N['fr_done'] = 'All done! Thanks for playing!'
# star rewards: one after practice, one after each story (5 total)
N['rw_1'] = 'You got a star! Great job practicing. Now let\'s hear some stories. Every time you finish a story, you get another star.'
N['rw_2'] = 'You got another star! That\'s two stars. Three more stories to go.'
N['rw_3'] = 'Three stars! Two more stories to go.'
N['rw_4'] = 'Four stars! Just one more story.'
N['vd_mid'] = 'You are halfway there! Time for a cartoon break. Then two more stories.'
N['dance_mid'] = 'You are halfway there! Let\'s do a little dance! Then two more stories.'
N['vd_end'] = 'And now, a cartoon just for you!'
N['rw_5'] = 'You got all five stars! You did it! Great job!'

DESIGN = dict(contents=CONTENTS, trials=TRIALS, practice=PRACTICE, versions=VERSIONS, narration=N)

if __name__ == '__main__':
    out = os.path.join(ROOT, 'design.json')
    json.dump(DESIGN, open(out, 'w'), indent=1)
    print('wrote', out, '| audio keys:', len(N))
