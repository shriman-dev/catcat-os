import ExtensionFeature from '../../utils/extensionFeature.js';
import { Delay } from '../../utils/delay.js';
import * as MessageTray from 'resource:///org/gnome/shell/ui/messageTray.js';
import { randomChoice } from '../../utils/utils.js';
import { AssetIcon } from '../../utils/ui/assetIcon.js';
import { settings } from '../../settings.js';
import TouchUpExtension from '../../extension.js';
import { Button } from '../../utils/ui/widgets.js';
import { css } from '../../utils/ui/css.js';
import showToast from '../../utils/ui/toast.js';
import { NotificationService } from '../../services/notificationService.js';

class DonationsFeature extends ExtensionFeature {
    // Time to wait before showing a donation; this is to not show the donation immediately upon login because
    // the user at that point probably is busy, and we don't want to uselessly annoy them:
    static NOTIFICATION_DELAY = 20; // in minutes
    // Time between donation prompt notifications:
    static NOTIFICATION_INTERVAL = 90 * 24 * 60 * 60 * 1000; // in ms; 90 days (~ quarter of a year)
    constructor(pm) {
        super(pm);
        // Read after a delay to not make this feature slow down startup:
        Delay.ms(700)
            .then(_ => this._initializeInstallationData())
            .then(data => this._maybeScheduleNotification(data));
    }
    async _initializeInstallationData() {
        try {
            const data = await this._readInstallationData();
            this._validateInstallationData(data);
            return data;
        }
        catch (e) {
            const data = {
                installedAt: Date.now(),
                promptedForDonationAt: null,
            };
            await this._writeInstallationData(data);
            return data;
        }
    }
    _maybeScheduleNotification(data) {
        if (data.dontAskAgain === true)
            return;
        const dt = data.promptedForDonationAt ?? data.installedAt;
        if (dt && Date.now() - dt > DonationsFeature.NOTIFICATION_INTERVAL) {
            Delay.min(DonationsFeature.NOTIFICATION_DELAY).then(() => this.showDonationNotification(data));
        }
    }
    /**
     * Show a panel notification asking the user to donate.
     */
    async showDonationNotification(data) {
        const notificationService = TouchUpExtension.instance.getFeature(NotificationService);
        const n = randomChoice(NOTIFICATION_VARIANTS);
        const notification = notificationService.create({
            title: n.title,
            body: n.body,
            gicon: new AssetIcon('positive-feedback-symbolic'),
            urgency: MessageTray.Urgency.NORMAL,
        });
        notification.connect('activated', () => this.openDonationPage());
        notification.addAction("Learn more", () => this.openDonationPage());
        notification.addAction("Not now", async () => {
            showToast("No problem – you'll receive a notification in a few months again!", [
                new Button({
                    label: 'Never ask again',
                    styleClass: 'button',
                    onClicked: async () => await this._writeInstallationData({
                        ...(data ?? await this._readInstallationData()),
                        dontAskAgain: true,
                    }),
                }),
                new Button({
                    iconName: 'window-close-symbolic',
                    style: css({ height: '10px' }),
                }),
            ]);
        });
        notificationService.show(notification);
        await this._writeInstallationData({
            ...(data ?? await this._readInstallationData()),
            promptedForDonationAt: Date.now(),
        });
    }
    openDonationPage() {
        if (!TouchUpExtension.instance)
            return;
        settings.initialPreferencesPage.set('donations');
        TouchUpExtension.instance.openPreferences();
    }
    async _readInstallationData() {
        return JSON.parse(settings.donations.installationData.get());
    }
    async _writeInstallationData(data) {
        try {
            settings.donations.installationData.set(JSON.stringify(data));
        }
        catch (e) {
        }
    }
    _validateInstallationData(data) {
        if (typeof data.installedAt !== 'number') {
            throw new Error("Missing or invalid field in installation data: 'installedAt'");
        }
        if (data.promptedForDonationAt != null && !['number', 'undefined'].includes(typeof data.promptedForDonationAt)) {
            throw new Error(`Invalid data type in installation data field 'promptedForDonation': ${typeof data.promptedForDonationAt}`);
        }
        if (data.dontAskAgain != null && !['boolean', 'undefined'].includes(typeof data.dontAskAgain)) {
            throw new Error(`Invalid data type in installation data field 'dontAskAgain': ${typeof data.dontAskAgain}`);
        }
    }
}
const NOTIFICATION_VARIANTS = [
    {
        "title": "Is TouchUp helpful for you? 🌟",
        "body": "Support its development by making a donation. Every contribution helps! 💖"
    },
    {
        "title": "Thank you for using TouchUp! ❤️",
        "body": "If you find it useful, consider supporting the project with a donation. Click to learn more."
    },
    {
        "title": "Help Keep TouchUp Going 🤝",
        "body": "Donations help cover development time and maintenance. Every little bit helps! ❤️"
    },
    {
        "title": "Consider Supporting TouchUp 🤝",
        "body": "We rely on your generosity to keep improving. Click here to donate. ❤️"
    },
    {
        "title": "Keep Us Coding! 💻",
        "body": "Your generosity powers innovation and independence. Make a donation today to support TouchUp! ❤️"
    },
    {
        "title": "Support Open Source ❤️",
        "body": "Your donations keep open-source projects like TouchUp alive. Help us grow! 🌟"
    },
    {
        "title": "Make a Difference 🌍",
        "body": "Your support fuels this project. Donate today to keep TouchUp going strong! 💪"
    },
    {
        "title": "Empower Open Platforms ✊",
        "body": "TouchUp makes GNOME more useful on tablets – and helps it challenge corporate giants. Your donation strengthens the fight for open software! 🌍"
    },
    {
        "title": "Open Source Needs You! 🛠️",
        "body": "Big Tech monopolies dominate mobile OSes — but you and TouchUp can help making GNOME an independent alternative. Donate today!"
    },
    {
        "title": "We have big plans for TouchUp... ",
        "body": "... and you can help making it happen! Take a look at what's coming, leave us some new ideas or make us faster with a small donation! 😄",
    },
    {
        "title": "TouchUp has a long bucket list! 🪣",
        "body": "Curios what else is coming? Have a look at the planned features and help us realize them with a small donation ❤️"
    }
];

export { DonationsFeature };
