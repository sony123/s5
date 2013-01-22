#ifndef PFOITEM_H
#define PFOITEM_H
#include "listModel.h"

class PfoItem : public ListItem {
    Q_OBJECT

public:
    enum PfoRoles {
        LocalRole = Qt::UserRole + 1,
        NameRole,
        LinkRole,
        ExcerptRole,
        IsYahooRole,
        NumRole,
        CostRole,
        GainRole,
        ValueRole
    };
    PfoItem(QObject* parent = 0) : ListItem (parent) {}
    explicit PfoItem(const QString &local,
                     const QString &name,
                     const QString &feedLink,
                     const QString &excerpt,
                     const bool &isYahoo,
                     const float &num,
                     const float &cost,
                     const float &gain,
                     const float &value,
                     QObject* parent = 0);
    QVariant data(int role) const;
    QHash<int, QByteArray> roleNames() const;
    inline QString local() const { return m_local; }
    inline QString name() const { return m_name; }
    inline QString feedLink() const { return m_link; }
    inline QString excerpt() const { return m_excerpt; }
    inline bool isYahoo() const { return m_isYahoo; }
    inline int num() const  { return m_num; }
    inline float cost() const { return m_cost; }
    inline float gain() const { return m_gain; }
    inline float value() const { return m_value; }

private:
    QString m_local;
    QString m_name;
    QString m_link;
    QString m_excerpt;
    bool m_isYahoo;
    float m_num;
    float m_cost;
    float m_gain;
    float m_value;
};

#endif // LOGITEM_H
